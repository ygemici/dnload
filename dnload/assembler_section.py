import re

from dnload.assembler_bss_element import AssemblerBssElement
from dnload.common import is_verbose
from dnload.elfling import ELFLING_UNCOMPRESSED
from dnload.platform_var import osarch_is_ia32
from dnload.platform_var import osarch_is_amd64
from dnload.platform_var import PlatformVar

########################################
# AssemblerSection #####################
########################################

class AssemblerSection:
  """Section in an existing assembler source file."""

  def __init__(self, section_name, section_tag = None):
    """Constructor."""
    self.__name = section_name
    self.__tag = section_tag
    self.__content = []

  def add_content(self, line):
    """Add one or more lines of content."""
    for ii in line.strip("\n").split("\n"):
      self.__content += [ii + "\n"]

  def clear_content(self):
    """Clear all content."""
    self.__content = []

  def crunch(self):
    """Remove all offending content."""
    while True:
      #lst = self.want_line(r'\s*\.file\s+(.*)')
      #if lst:
      #  self.erase(lst[0])
      #  continue
      #lst = self.want_line(r'\s*\.globl\s+(.*)')
      #if lst:
      #  self.erase(lst[0])
      #  continue
      #lst = self.want_line(r'\s*\.ident\s+(.*)')
      #if lst:
      #  self.erase(lst[0])
      #  continue
      #lst = self.want_line(r'\s*\.type\s+(.*)')
      #if lst:
      #  self.erase(lst[0])
      #  continue
      #lst = self.want_line(r'\s*\.size\s+(.*)')
      #if lst:
      #  self.erase(lst[0])
      #  continue
      lst = self.want_line(r'\s*\.section\s+(.*)')
      if lst:
        self.erase(lst[0])
        continue
      lst = self.want_line(r'\s*\.(bss)\s+')
      if lst:
        self.erase(lst[0])
        continue
      lst = self.want_line(r'\s*\.(data)\s+')
      if lst:
        self.erase(lst[0])
        continue
      lst = self.want_line(r'\s*\.(text)\s+')
      if lst:
        self.erase(lst[0])
        continue
      break
    if osarch_is_amd64():
      self.crunch_amd64(lst)
    elif osarch_is_ia32():
      self.crunch_ia32(lst)
    self.__tag = None

  def crunch_amd64(self, lst):
    """Perform platform-dependent crunching."""
    self.crunch_entry_push("_start")
    self.crunch_entry_push(ELFLING_UNCOMPRESSED)
    self.crunch_jump_pop(ELFLING_UNCOMPRESSED)
    lst = self.want_line(r'\s*(int\s+\$0x3|syscall)\s+.*')
    if lst:
      ii = lst[0] + 1
      jj = ii
      while True:
        if len(self.__content) <= jj or re.match(r'\s*\S+\:\s*', self.__content[jj]):
          if is_verbose():
            print("Erasing function footer after '%s': %i lines" % (lst[1], jj - ii))
          self.erase(ii, jj)
          break
        jj += 1

  def crunch_entry_push(self, op):
    """Crunch amd64/ia32 push directives from given line listing."""
    lst = self.want_label(op)
    if not lst:
      return
    ii = lst[0] + 1
    jj = ii
    stack_decrement = 0
    stack_save_decrement = 0
    reinstated_lines = []
    while True:
      current_line = self.__content[jj]
      match = re.match(r'\s*(push\S).*%(\S+)', current_line, re.IGNORECASE)
      if match:
        if is_stack_save_register(match.group(2)):
          stack_save_decrement += get_push_size(match.group(1))
        else:
          stack_decrement += get_push_size(match.group(1))
        jj += 1
        continue;
      # Preserve comment lines as they are.
      match = re.match(r'^\s*[#;].*', current_line, re.IGNORECASE)
      if match:
        reinstated_lines += [current_line]
        jj += 1
        continue
      # Saving stack pointer or sometimes initializing edx seem to be within pushing.
      match = re.match(r'\s*mov.*,\s*%(rbp|ebp|edx).*', current_line, re.IGNORECASE)
      if match:
        if is_stack_save_register(match.group(1)):
          stack_save_decrement = 0
        reinstated_lines += [current_line]
        jj += 1
        continue;
      # xor (zeroing) seems to be inserted in the 'middle' of pushing.
      match = re.match(r'\s*xor.*\s+%(\S+)\s?,.*', current_line, re.IGNORECASE)
      if match:
        reinstated_lines += [current_line]
        jj += 1
        continue
      match = re.match(r'\s*sub.*\s+[^\d]*(\d+),\s*%(rsp|esp)', current_line, re.IGNORECASE)
      if match:
        total_decrement = int(match.group(1)) + stack_decrement + stack_save_decrement
        self.__content[jj] = re.sub(r'\d+', str(total_decrement), current_line)
      break
    if is_verbose():
      print("Erasing function header from '%s': %i lines" % (op, jj - ii - len(reinstated_lines)))
    self.erase(ii, jj)
    self.__content[ii:ii] = reinstated_lines

  def crunch_ia32(self, lst):
    """Perform platform-dependent crunching."""
    self.crunch_entry_push("_start")
    self.crunch_entry_push(ELFLING_UNCOMPRESSED)
    self.crunch_jump_pop(ELFLING_UNCOMPRESSED)
    lst = self.want_line(r'\s*int\s+\$(0x3|0x80)\s+.*')
    if lst:
      ii = lst[0] + 1
      jj = ii
      while True:
        if len(self.__content) <= jj or re.match(r'\s*\S+\:\s*', self.__content[jj]):
          if is_verbose():
            print("Erasing function footer after interrupt '%s': %i lines." % (lst[1], jj - ii))
          self.erase(ii, jj)
          break
        jj += 1

  def crunch_jump_pop(self, op):
    """Crunch popping before a jump."""
    lst = self.want_line(r'\s*(jmp\s+%s)\s+.*' % (op))
    if not lst:
      return
    ii = lst[0]
    jj = ii - 1
    while True:
      if (0 > jj) or not re.match(r'\s*(pop\S).*', self.__content[jj], re.IGNORECASE):
        if is_verbose():
          print("Erasing function footer before jump to '%s': %i lines" % (op, ii - jj - 1))
        self.erase(jj + 1, ii)
        break
      jj -= 1

  def empty(self):
    """Tell if this section is empty."""
    if not self.__content:
      return True
    return False

  def erase(self, first, last = None):
    """Erase lines."""
    if not last:
      last = first + 1
    if first > last:
      return
    self.__content[first:last] = []

  def extract_bss(self, und_symbols):
    """Extract a variable that should go to .bss section."""
    # Test for relevant .bss element.
    found = self.extract_bss_object()
    if found:
      return AssemblerBssElement(found[0], found[1], und_symbols)
    found = self.extract_comm_object()
    if found:
      return AssemblerBssElement(found[0], found[1], und_symbols)
    self.minimal_align()
    self.crunch()
    return None

  def extract_comm_object(self):
    """.comm extract."""
    idx = 0
    while True:
      lst = self.want_line(r'\s*\.local\s+(\S+).*', idx)
      if not lst:
        break
      attempt = lst[0]
      name = lst[1]
      idx = attempt + 1
      lst = self.want_line(r'\s*\.comm\s+%s\s*,(.*)' % (name), idx)
      if not lst:
        continue
      size = lst[1]
      match = re.match(r'\s*(\d+)\s*,\s*(\d+).*', size)
      if match:
        size = int(match.group(1))
      else:
        size = int(size)
      self.erase(attempt, lst[0] + 1)
      return (name, size)
    return None

  def extract_bss_object(self):
    """Extract .bss objects signified with .object."""
    idx = 0
    while True:
      lst = self.want_line(r'\s*.type\s+(\S+),\s+[@%]object', idx)
      if not lst:
        break
      first_line = lst[0]
      name = lst[1]
      idx = first_line + 1
      if not lst:
        continue
      lst = self.want_line(r'\s*(%s)\:' % (name), lst[0] + 1, 2)
      if not lst:
        continue
      lst = self.want_line(r'\s*\.(?:space|zero)\s+(\d+)', lst[0] + 1, 2)
      if not lst:
        continue
      last_line = lst[0] + 1
      bss_size = int(lst[1])
      # Check if there's an additional label to remove.
      lst = self.want_line(r'\s*\.(globl|local)\s+%s\s*' % name, first_line - 1, 1)
      if lst:
        first_line = lst[0]
      # Erase and exit.
      self.erase(first_line, last_line)
      return (name, bss_size)
    return None

  def gather_labels(self):
    """Gathers all labels."""
    ret = []
    for ii in self.__content:
      match = re.match(r'((\.L|_ZL)[^:,\s\(]+)', ii)
      if match:
        ret += [match.group(1)]
      match = re.match(r'^([^\.:,\s\(]+):', ii)
      if match:
        ret += [match.group(1)]
    return ret

  def generate_file_output(self):
    """Generate output for writing to a file."""
    ret = ""
    if self.__tag:
      ret += self.__tag
    for ii in self.__content:
      ret += ii
    return ret

  def get_name(self):
    """Accessor."""
    return self.__name

  def merge_content(self, other):
    """Merge content with another section."""
    self.__content += other.__content

  def minimal_align(self):
    """Remove all .align declarations, replace with desired alignment."""
    desired = int(PlatformVar("align"))
    adjustments = []
    for ii in range(len(self.__content)):
      line = self.__content[ii]
      match = re.match(r'.*\.align\s+(\d+).*', line)
      if match:
        align = int(match.group(1))
        self.__content[ii] = "  .balign %i\n" % (desired)
        # Due to GNU AS compatibility modes, .align may mean different things.
        if osarch_is_amd64() or osarch_is_ia32():
          if desired != align:
            adjustments += ["%i -> %i" % (align, desired)]
        else:
          align = 1 << align
          if desired != align:
            adjustments += ["%i -> %i" % (align, desired)]
    if is_verbose() and adjustments:
      print("Alignment adjustment(%s): %s" % (self.get_name(), ", ".join(adjustments)))

  def replace_content(self, op):
    """Replace content of this section with content of given section."""
    self.__content = op.__content

  def replace_entry_point(self, op):
    """Replaces an entry point with given entry point name from this section, should it exist."""
    lst = self.want_entry_point()
    if lst:
      self.__content[lst[0]] = "%s:\n" % op

  def replace_labels(self, labels, append):
    """Replace all labels."""
    for ii in range(len(self.__content)):
      src = self.__content[ii]
      for jj in labels:
        dst = src.replace(jj, jj + append)
        if dst != src:
          self.__content[ii] = dst
          break

  def want_entry_point(self):
    """Want a line matching the entry point function."""
    return self.want_label("_start")

  def want_label(self, op):
    """Want a label from code."""
    return self.want_line(r'\s*\S*(%s)\S*\:.*' % (op))

  def want_line(self, op, first = 0, count = 0x7FFFFFFF):
    """Want a line matching regex from object."""
    for ii in range(first, min(len(self.__content), first + count)):
      match = re.match(op, self.__content[ii], re.IGNORECASE)
      if match:
        return (ii, match.group(1))
    return None

  def __str__(self):
    """String representation."""
    return "AssemblerSection('%s', %i)" % (self.__name, len(self.__content))

########################################
# Functions ############################
########################################

def get_push_size(op):
  """Get push side increment for given instruction or register."""
  ins = op.lower()
  if ins == 'pushq':
    return 8
  elif ins == 'pushl':
    return 4
  else:
    raise RuntimeError("push size not known for instruction '%s'" % (ins))

def is_stack_save_register(op):
  """Tell if given register is used for saving the stack."""
  return op.lower() in ('rbp', 'ebp')

func toByteSeq*(s: string): seq[byte] =
  ## Helper used to convert data loaded by readStatic() to sequence
  if s.len == 0:
    return @[]
  result = newSeq[byte](s.len)
  copyMem(addr result[0], addr s[0], s.len)

proc generateName*(name, prefix: string, lastNumber: var uint32): string =
  ## Generates names from prefix and number like "Button 1" when name is empty
  if name.len != 0:
    return name
  inc lastNumber
  return prefix & " " & $lastNumber
   
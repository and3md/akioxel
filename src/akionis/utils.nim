

func toByteSeq*(s: string): seq[byte] =
  ## Helper used to convert data loaded by readStatic() to sequence
  if s.len == 0:
    return @[]
  result = newSeq[byte](s.len)
  copyMem(addr result[0], addr s[0], s.len)
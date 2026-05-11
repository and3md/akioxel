

func toByteSeq*(s: string): seq[byte] =
  if s.len == 0:
    return @[]
  result = newSeq[byte](s.len)
  copyMem(addr result[0], addr s[0], s.len)
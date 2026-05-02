# `File.binread(path).bytes` — sp_str_bytes uses null-termination
# and stops at the first 0x00 byte, so for binary data (e.g. .nes
# ROM files where 0x00 appears mid-file) we need a dedicated
# helper that reads with the actual file size.
#
# `File.binread(path)` standalone is aliased to File.read.

# Set up a binary file with embedded NULs via a shell command.
# spinel's File.write uses fputs and would stop at the first NUL.
path = "/tmp/spinel_binread_test.bin"
`printf 'AB\\000CD\\000EF' > #{path}`

# Pattern-matched: emits sp_file_binread_bytes(path) which reads
# the file by its actual byte count, NOT through sp_str_bytes.
arr = File.binread(path).bytes
puts arr.length               # 8
puts arr[0]                   # 65 (A)
puts arr[1]                   # 66 (B)
puts arr[2]                   # 0  (NUL)
puts arr[3]                   # 67 (C)
puts arr[4]                   # 68 (D)
puts arr[5]                   # 0  (NUL)
puts arr[6]                   # 69 (E)
puts arr[7]                   # 70 (F)

# `File.binread` standalone aliases `File.read`. spinel's strings
# are null-terminated so any NUL in the result is a hard stop —
# this branch is just verifying the alias resolves and returns
# something string-shaped.
puts File.binread(path)[0, 2] # AB

File.delete(path) if File.exist?(path)

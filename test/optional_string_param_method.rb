def parse(source, file_path = nil)
  if file_path
    puts file_path.length
  else
    puts source.length
  end
end

parse("abc", "name.rb")
parse("abc")
parse("longer", "another_name.rb")

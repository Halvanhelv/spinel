# `arr.map { array_block }` — outer recv is a typed Array, block
# returns a typed array (`(0..i).to_a` here is int_array). Without
# the fix, two issues conspire:
#
#   - infer_method_name_type returned int_array, so the ivar `@rows`
#     was typed as int_array. The outer accumulator was an
#     sp_IntArray pushed via sp_IntArray_push — but each iteration's
#     value was an sp_IntArray pointer reinterpreted as mrb_int,
#     which gcc rejects on -Wint-conversion.
#   - Even if the cast were silent, the inner arrays would not be
#     traced from an IntArray slot and could be collected mid-loop.
#
# After the fix, the result is `<elem>_ptr_array` and the codegen
# accumulator is an sp_PtrArray pushed via sp_PtrArray_push.

class C
  def initialize
    @rows = [1, 6].map { |i| (0..i).to_a }
  end

  def show
    @rows.each do |row|
      row.each { |x| print x, " " }
      puts
    end
  end
end

C.new.show

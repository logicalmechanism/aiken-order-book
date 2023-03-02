use order_book/math

test simple_percentage() {
  math.percentage(1000000, 40) == 25000
}

test rounding_percentage() {
  math.percentage(123456789, 35) == 3527336
}

test is_in_range() {
  math.is_int_in_range(1000000, 40, 985000) == True
}

test is_not_in_range() {
  math.is_int_in_range(1000000, 40, 955000) == False
}

test good_effective_price() {
  math.effective_price(123456, 654321) == 188678
}

test bad_effective_price() {
  math.effective_price(123456, 0) == 0
}

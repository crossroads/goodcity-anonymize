require './utils/string'

class Inventory

  # E.g. F123245, F123245Q, F123245Q12
  def self.anonymize_inventory_number(inventory_number)
    return "" if (inventory_number || "").blank?
    prefix = inventory_number.scan(/^[A-Za-z]/).join
    prefix = "X" if prefix.blank?
    suffix = inventory_number.scan(/[Qq]{1}\d*/).join
    srand(inventory_number.hash)
    prefix + ("%06d" % rand(1..999999).to_s) + suffix
  end

  # e.g. L12324, S1234, GC-12345, Dec2018Stock -> becomes GC-12345
  def self.anonymize_designation_name(designation_name)
    return "" if (designation_name || "").blank?
    prefix = designation_name.scan(/^[L,S,C,GC-]*/)[0]
    prefix = "GC-" if prefix.blank?
    srand(designation_name.hash)
    prefix + ("%05d" % rand(1..99999).to_s)
  end

  # +85261234567
  def self.random_hk_mobile
    "+852" + %w(5 6 7 8 9).sample + rand(10**6..10**7-1).to_s
  end

  # CAS-12345
  def self.random_case_number
    "CAS-" + rand(10**4..10**5-1).to_s
  end

end
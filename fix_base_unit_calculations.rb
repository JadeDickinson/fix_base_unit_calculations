require 'pry'

class FixBaseUnitCalculations
  GENERAL = /\(\$base-unit \* 8\)\s*[*\/]\s*\d*\.*\d*/
  MULTIPLY = /\(\$base-unit \* 8\)\s*\*\s*\d*\.*\d*/
  DIVIDE = /\(\$base-unit \* 8\)\s*\/\s*\d*\.*\d*/

  NUMBER_BEFORE = /\d+\.*\d*\s+\$base-unit\s\*\s\d\.*\d*/
  NUMBER_AFTER = /\$base-unit\s\*\s\d\.*\d*\s\d+\.*\d*/
  BRACKETED_BASE_UNIT_BEFORE = /\(\$base-unit \* \d\.*\d*\)\s\$base-unit\s\*\s\d\.*\d*/
  BRACKETED_BASE_UNIT_AFTER = /\$base-unit\s\*\s\d\.*\d*\s\(\$base-unit \* \d\.*\d*\)/

  UNBRACKETED_BASE_UNIT_SPACE_BEFORE = /\s\$base-unit\s\*\s\d+\.*\d*/
  UNBRACKETED_BASE_UNIT_SPACE_AFTER = /\$base-unit\s\*\s\d+\.*\d*\s/
  UNBRACKETED_BASE_UNIT_SEMICOLON_AFTER = /\$base-unit\s\*\s\d+\.*\d*\;/

  UNBRACKETED_ALONGSIDE_OTHER_VALUES = /(?-mix:\d+\.*\d*\s+\$base-unit\s\*\s\d\.*\d*)|(?-mix:\$base-unit\s\*\s\d\.*\d*\s\d+\.*\d*)|(?-mix:\(\$base-unit \* \d\.*\d*\)\s\$base-unit\s\*\s\d\.*\d*)|(?-mix:\$base-unit\s\*\s\d\.*\d*\s\(\$base-unit \* \d\.*\d*\))/

  # This will only fix the files in the folder at that level.
  def run_on_folder(folder)
    files_array = Dir.open(folder)
    return if files_array.entries.empty?
    files_array.each do |file_name|
      next if File.directory? file_name
      run(folder + file_name)
    end
  end

  # Fix one file
  def run(file_name)
    text = File.read(file_name)

    text.gsub!(GENERAL) do |matching_text|
      case matching_text
      when MULTIPLY
        "$base-unit * #{trim_trailing_zeros(8 * send_back_only_number(matching_text))}"
      when DIVIDE
        divisor = send_back_only_number(matching_text)
        if divisor == 8.0
          '$base-unit'
        else
          "$base-unit * #{trim_trailing_zeros(8 / divisor)}"
        end
      end
    end

    if text.match?(UNBRACKETED_ALONGSIDE_OTHER_VALUES)
      surround_base_unit_calc_with_brackets(text)
    end
    File.open(file_name, 'w') { |file| file.puts text }
  end

  private

  def surround_base_unit_calc_with_brackets(text)
    text.gsub!(BRACKETED_BASE_UNIT_BEFORE) do |matching_text|
      fix_unbracketed_calculation(matching_text)
    end
    text.gsub!(BRACKETED_BASE_UNIT_AFTER) do |matching_text|
      fix_unbracketed_calculation(matching_text)
    end
    text.gsub!(NUMBER_BEFORE) do |matching_text|
      fix_unbracketed_calculation(matching_text)
    end
    text.gsub!(NUMBER_AFTER) do |matching_text|
      fix_unbracketed_calculation(matching_text)
    end
    text
  end

  def fix_unbracketed_calculation(matching_text)
    if matching_text.match?(UNBRACKETED_BASE_UNIT_SPACE_BEFORE)
      matching_unbracket = matching_text.match(UNBRACKETED_BASE_UNIT_SPACE_BEFORE).to_s
      matching_unbracket = matching_unbracket[1..matching_unbracket.length-1]
      matching_text.gsub!(UNBRACKETED_BASE_UNIT_SPACE_BEFORE, " (#{matching_unbracket})")
    elsif matching_text.match?(UNBRACKETED_BASE_UNIT_SPACE_AFTER)
      matching_unbracket = matching_text.match(UNBRACKETED_BASE_UNIT_SPACE_AFTER).to_s
      matching_unbracket = matching_unbracket[0..matching_unbracket.length-2]
      matching_text.gsub!(UNBRACKETED_BASE_UNIT_SPACE_AFTER, "(#{matching_unbracket}) ")
    end
    matching_text
  end

  def trim_trailing_zeros(number)
    format('%g', format('%.2f', number))
  end

  def send_back_only_number(text)
    text.sub('($base-unit * 8)', '').delete('*').delete('/').delete(' ').to_f
  end
end

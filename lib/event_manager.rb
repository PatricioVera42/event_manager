require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def valid_phone_number(phonenumber)
  clean_number = phonenumber.to_s.gsub(' ', '').gsub('(', '').gsub(')', '').gsub('-', '')
  if clean_number.length == 11 && clean_number[0] == '1'
    real_number = clean_number.slice(1..10)
  elsif clean_number.length == 10
    real_number = clean_number
  else 
    real_number = '# N/a'
  end
  if real_number.length == 10
    display_phonenumber = real_number.insert(6,'-').insert(3,') ').insert(0,'(')
  else
    display_phonenumber = real_number
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = valid_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

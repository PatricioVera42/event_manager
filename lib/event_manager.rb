require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phonenumber)
  clean_number = phonenumber.to_s.gsub(' ', '').gsub('(', '').gsub(')', '').gsub('-', '')
  if clean_number.length == 11 && clean_number[0] == '1'
    ten_digit_number = clean_number.slice(1..10)
  elsif clean_number.length == 10
    ten_digit_number = clean_number
  else 
    ten_digit_number = '# N/a'
  end
  if ten_digit_number.length == 10
    result_number = ten_digit_number.insert(6,'-').insert(3,') ').insert(0,'(')
  else
    result_number = ten_digit_number
  end
end

def day_of_week(hashkey)
  case hashkey
  when '0'
    'Sunday'
  when '1'
    'Monday'
  when '2'
    'Tuesday'
  when '3'
    'Wednesday'
  when '4'
    'Thursday'
  when '5'
    'Friday'
  when'6'
    'Saturday'
  end
end


def most_common_day
  contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
  common_day = Hash.new 
  contents.each do |row|
    date = DateTime.strptime(row[:regdate], '%D %R')
    wday = date.wday
    if common_day.include?(wday) == false
      common_day[wday] = 1
    else
      common_day[wday] += 1
    end
  end
  most_common_day = common_day.key(common_day.values.sort.slice(0))
  p most_common_day
  day_of_week(most_common_day.to_s)
end

def most_common_hour
  contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)
  common_hours = Hash.new
  contents.each do |row|
    date = DateTime.strptime(row[:regdate], '%D %R')
    hour = date.hour
    if common_hours.include?(hour) == false
      common_hours[hour] = 1
    else
      common_hours[hour] += 1
    end
  end
    most_common_hour = common_hours.key(common_hours.values.sort.slice(0))
    return most_common_hour
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
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end

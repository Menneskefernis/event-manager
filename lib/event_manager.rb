require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
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
    puts "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"
  
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  number = phone_number.gsub(/[\.( )-]/, '')

  case true
  when number.size < 10
    "N/A"
  when number.size > 11
    "N/A"
  when number.size == 11 && !number[0].to_i == 1
    "N/A"
  when number.size == 11 && number[0].to_i == 1
    number.slice(0, 10)
  else
    number
  end
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

$registration_hours = Hash.new(0)
$registration_weekdays = Hash.new(0)

def save_registration_hour(date)
  format = '%m/%d/%Y %H:%M'
  $registration_hours[DateTime.strptime(date, format).hour] += 1
end

def save_weekday_registration(date)
  format = '%m/%d/%Y'
  $registration_weekdays[DateTime.strptime(date, format).wday] += 1
end

def calculate_peak(hash)
  #hash.max_by{|k,v| v}[0]
  
  hash = hash.sort_by {|k,v| v}.reverse
  [hash[0][0], hash[1][0]]
end

def num_to_weekday(number)
  case number
  when 0
    "Sunday"
  when 1
    "Monday"
  when 2
    "Tuesday"
  when 3
    "Wednesday"
  when 4
    "Thursday"
  when 5
    "Friday"
  when 6
    "Saturday"
  end
end

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  
  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  registration_date = row[:regdate]
  
  save_registration_hour(registration_date)

  save_weekday_registration(registration_date)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

peak_days = calculate_peak($registration_weekdays)
puts "Peak days are: #{peak_days.map { |day| num_to_weekday(day) }.join(', ')}"
puts "Peak hours are: #{calculate_peak($registration_hours).join(', ')}"
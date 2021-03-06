require 'open-uri'
require 'nokogiri'
require 'date'
require 'json'

def scrap_year(output_dir)
  result = {}
  (1..12).each do |month_index|
    (1..31).each do |day_index|
      begin
        day, month = form_date(day_index, month_index)

        puts "Scraping #{month} #{day}..."

        description, events, births, deaths = extract_from(day, month)

        result["#{month}-#{day}".to_sym] = {
          description: description, events: events, births: births, deaths: deaths
        }
      rescue NoMethodError
        puts 'It seems this date does not have any episodes.'
      end
    end
  end

  export_to_file(result, output_dir)
end

private

def form_date(day_index, month_index)
  date = Date._strptime("#{day_index}/#{month_index}", '%d/%m')
  [date[:mday], Date::MONTHNAMES[date[:mon]]]
end

def extract_from(day, month)
  html = Nokogiri::HTML open("https://en.wikipedia.org/wiki/#{month}_#{day}")

  description = html.css('#mw-content-text p')
                    .map(&:text)
                    .find { |text| text.include?("#{month} #{day}") }

  events = parse_ul html.css('#Events')[0].parent.next_element
  births = parse_ul html.css('#Births')[0].parent.next_element
  deaths = parse_ul html.css('#Deaths')[0].parent.next_element

  [description, events.compact, births.compact, deaths.compact]
end

def parse_ul(ul)
  ul.css('li').map do |li|
    year, *text = li.text.split(' – ')

    next unless year && !text.empty?
    { year: year, data: text.join(' – '), kw: parse_keywords(li) }
  end
end

def parse_keywords(li)
  li.css('a').map { |a| { title: a['title'], href: a['href'] } }
end

def export_to_file(hash_data, dir)
  File.write(dir, hash_data.to_json)
  puts "Results stored in #{dir}"
end

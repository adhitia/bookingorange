module DateHelper
    def indonesian_date(date)
      return "" unless date.present?
      
      day_names = {
        "Monday"    => "Senin",
        "Tuesday"   => "Selasa",
        "Wednesday" => "Rabu",
        "Thursday"  => "Kamis",
        "Friday"    => "Jumat",
        "Saturday"  => "Sabtu",
        "Sunday"    => "Minggu"
      }
      
      month_names = {
        "January"   => "Januari",
        "February"  => "Februari",
        "March"     => "Maret",
        "April"     => "April",
        "May"       => "Mei",
        "June"      => "Juni",
        "July"      => "Juli",
        "August"    => "Agustus",
        "September" => "September",
        "October"   => "Oktober",
        "November"  => "November",
        "December"  => "Desember"
      }
      
      "#{day_names[date.strftime('%A')]}, #{date.strftime('%d')} #{month_names[date.strftime('%B')]} #{date.strftime('%Y')}"
    end

    def convert_to_indonesian(day_name)
      mapping = {
        "Monday"    => "Senin",
        "Tuesday"   => "Selasa",
        "Wednesday" => "Rabu",
        "Thursday"  => "Kamis",
        "Friday"    => "Jumat",
        "Saturday"  => "Sabtu",
        "Sunday"    => "Minggu"
      }
      mapping[day_name] || day_name
    end
    
  end
  
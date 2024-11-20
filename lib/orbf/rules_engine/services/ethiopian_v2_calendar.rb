module Orbf
    module RulesEngine
      class EthiopianV2Calendar
  
        def to_invoicing_period(year, quarter)
          "#{year}NovQ#{quarter}"
        end
  
        def each_periods(period, frequency, &block)
          PeriodIterator.each_periods(period, frequency, &block)
        end
  
        def periods(period, frequency)
          PeriodIterator.periods(period, frequency)
        end
  
        def from_iso(date)
            jdn = date.jd
            era = if jdn >= JD_EPOCH_OFFSET_AMETE_MIHRET + 365
                    JD_EPOCH_OFFSET_AMETE_MIHRET
                  else
                    JD_EPOCH_OFFSET_AMETE_ALEM
                  end
            r = (jdn - era).modulo(1461)
            n = r.modulo(365) + (365 * (r / 1460))
            eyear = 4 * ((jdn - era) / 1461) + r / 365 - r / 1460
            emonth = (n / 30) + 1
            eday = n.modulo(30) + 1
            begin
              Date.new(eyear, emonth, eday)
            rescue ArgumentError
              begin
                Date.new(eyear, emonth, eday - 1)
              rescue ArgumentError
                Date.new(eyear, emonth, eday - 2)
            end
            end
          end
    
          def to_iso(ethiopic)
            year = ethiopic.year
            month = ethiopic.month
            day = ethiopic.day
            era = if year <= 0
                    JD_EPOCH_OFFSET_AMETE_ALEM
                  else
                    JD_EPOCH_OFFSET_AMETE_MIHRET
                  end
            jdn = jdn_from_ethiopic(year, month, day, era)
            gregorian_from_jdn(jdn)
          end
    
          private
    
          # Ethiopic: Julian date offset
          JD_EPOCH_OFFSET_AMETE_MIHRET = 1_723_856
          JD_EPOCH_OFFSET_AMETE_ALEM   = -285_019
    
          # Calculates the julian day number from given Ethiopic calendar
          def jdn_from_ethiopic(year, month, day, era)
            (era + 365) + (365 * (year - 1)) + (year / 4) + (30 * month) + (day - 31)
          end
    
          # gregorian calendar date from julian day number
          def gregorian_from_jdn(jdn)
            Date.jd(jdn).new_start(Date::GREGORIAN)
          end
        end
      end
    end    
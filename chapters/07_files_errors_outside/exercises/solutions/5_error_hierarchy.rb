# Solution to Exercise 5
class AppError < StandardError; end
class NotFound      < AppError; end
class Unauthorized  < AppError; end
class BadRequest    < AppError; end

def simulate(kind)
  case kind
  when :not_found      then raise NotFound, "user not found"
  when :unauthorized   then raise Unauthorized, "missing token"
  when :bad_request    then raise BadRequest, "bad input"
  else                       raise AppError, "generic"
  end
end

if __FILE__ == $PROGRAM_NAME
  # Specific catch:
  begin
    simulate(:not_found)
  rescue NotFound => e
    puts "specific NotFound: #{e.message}"
  end

  # Generic catch (catches all four):
  %i[not_found unauthorized bad_request other].each do |kind|
    begin
      simulate(kind)
    rescue AppError => e
      puts "generic #{e.class}: #{e.message}"
    end
  end
end

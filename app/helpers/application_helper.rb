module ApplicationHelper

	def isAdmin?
		current_user.role == "admin"
	end
	
	def show_flashes
    js = ""
    flash.each do |f|
      js += "showNotice('flash#{f.shift}s', '#{j f.join(',')}');"
    end
    flash.discard
    return js
	end
	
end

module ApplicationHelper

	def isAdmin?
		current_user.role == "admin"
	end
end

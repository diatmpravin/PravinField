Feature: Logout
	After done my all work on HDO site
	As a authorized user
	I want to logout successful
	
	Scenario: I want to logout
		Given I am logged in
		When I logout
		Then I will see signed out message
		When I return to the site
		Then I should be signed out

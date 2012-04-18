Feature: Edit profiel details
	I am able to edit profile
	As a registered user
	I want to edit my profile
	
	Scenario: I want to edit my profile details
		Given I am logged in
		When I edit my profile details
		Then I should see an account edited message

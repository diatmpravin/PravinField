Feature: Admin login
	I want to access site to manage HDO site
	As an admin
	I want to login
	
	Scenario: Admin login
		Given I am admin of HDO 
		When I login with valid credentials as admin
		Then I see a successful login message
		And I should be signed in as admin

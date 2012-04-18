Feature: Register new user
	If any body want to access HDO site
	As a admin
	I want to create a new user
	
	Background:
		Given I am not logged in
		
	Scenario: Admin create user with valid data
		When Admin create user with valid data
		Then Admin should see a successful sign up message	

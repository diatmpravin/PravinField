## UTILITY METHODS
def createVisitor
	@visitor ||= { :name=> "HDO", :email =>"mpravin@maisasolutions.com", :password => "aaaa1234", :password_confirmation => "aaaa1234"}
end

def adminvisitor
	@adminData ||= { :name=> "Maisa", :email =>"hdo.whiteblt@gmail.com", :password => "maisa1234", :password_confirmation => "maisa1234", :role => "admin"}
end

def createAdmin
	adminvisitor
	deleteAdmin
	@admin = FactoryGirl.create(:user, name: @adminData[:name], email: @adminData[:email], password: @adminData[:password] , password_confirmation: @adminData[:password_confirmation] , role: @adminData[:role])
end

def createUser
	createVisitor
  deleteUser
  @user = FactoryGirl.create(:user, email: @visitor[:email], name: @visitor[:name], password: @visitor[:password], password_confirmation: @visitor[:password_confirmation])
end

def adminLogIn
	visit '/users/sign_in'
	fill_in "Email", :with => @adminData[:email]	
	fill_in "Password", :with => @adminData[:password]
	click_button "Sign in"	
end

def deleteAdmin
	@admin ||= User.first conditions: { :role => @adminData[:role]}
	@admin.destroy unless @admin.nil?
end

def deleteUser
	@user ||= User.first conditions: { :email => @visitor[:email] }
	@user.destroy unless @user.nil?
end

def signUp	
	createAdmin
	createVisitor
	visit '/users/sign_up'
	fill_in "Name", :with => @visitor[:name]
	fill_in "Email", :with => @visitor[:email]
	fill_in "Password", :with => @visitor[:password]
	fill_in "Password confirmation", :with => @visitor[:password_confirmation]
	click_button "Create"
end

def deleteUser
	@user ||= User.first conditions: { :email => @visitor[:email]}
	@user.destroy unless @user.nil? 
end

def signIn
	visit '/users/sign_in'
	fill_in "Email", :with => @visitor[:email]	
	fill_in "Password", :with => @visitor[:password]
	click_button "Sign in"
end

## GIVEN
Given /^I am not logged in$/ do
  visit "/users/sign_out"
end

Given /^I do not exit as a user$/ do
  visit '/users/sign_in'
end

Given /^I exist as a user$/ do
  createUser
end

Given /^I am logged in$/ do
  createUser
  signIn
end

Given /^I am admin of HDO$/ do
  visit '/users/sign_in'
end



## WHEN
When /^Admin create user with valid data$/ do
  createAdmin  
  signUp
end

When /^I sign in with valid credentials$/ do
  createVisitor
  signIn
end

When /^I login with valid credentials$/ do
	createVisitor
  signIn
end

When /^I return to the site$/ do
  visit '/'
end

When /^I sign in with wrong email$/ do
  @visitor = @visitor.merge(:email => "wrongEmail@gmail.com")
  signIn
end

When /^I sign with a wrong password$/ do
  @visitor = @visitor.merge(:password => "incorrentPassword")
  signIn
end

When /^I edit my profile details$/ do
  click_link "Edit account"
  page.should have_content "Edit profile details"
  fill_in "Name", :with => "newName"
  fill_in "Current password", :with => @visitor[:password]  
  click_button "Update"
end

When /^I logout$/ do
  visit '/users/sign_out'
end

When /^I login with valid credentials as admin$/ do
  createAdmin
  adminLogIn
end




## THEN
Then /^Admin should see a successful sign up message$/ do
  page.should have_content "Welcome! You have signed up successfully."
end

Then /^I see an invalid login message$/ do
  page.should have_content "Invalid email or password"
end

Then /^I should be signed out$/ do
  page.should have_content "Login"
  page.should_not have_content "Logout"
end

Then /^I see a successful login message$/ do	  
  page.should have_content "Signed in successfully."
end

Then /^I should be signed in$/ do    
  page.should have_content "Logout"
  page.should_not have_content "Login"
  page.should have_content "Edit account"  
end

Then /^I should see an account edited message$/ do
  page.should have_content "You updated your account successfully."
end

Then /^I will see signed out message$/ do
  page.should have_content "You need to sign in or sign up before continuing."
end

Then /^I should be signed in as admin$/ do
  page.should have_content "Create user"
  page.should have_content "Edit account"
end






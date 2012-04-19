task :test => :environment do
	Rake::Task["spec"].invoke
end
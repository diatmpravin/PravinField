desc "fetch mws orders"
task :mws_fetch_orders => :environment do
	store = Store.find_by_name("HDO")
	store.fetch_recent_orders
	sleep 60
	store.reprocess_orders_missing_items
end
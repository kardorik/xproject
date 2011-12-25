# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_xproject_session',
  :secret      => '5e6189d470d823bdd9071829787ad8491c5f2ed7e1873a67252c897a3babe7fd8e8b63951e5ed17b5ebd938d68049104a509c49fd73caf7cc84613527a94e20a'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

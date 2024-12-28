TroupeIT V2 MongoDB Migration
----------
Notes: 

* We are running mongo version 3.x in prod. 
* We want to get up to monogdb version 7 or better.
* The upgrade process is 5 -> 6 -> 7
* This work only gets us to version 5.

Things I had to do to get access:

1. `docker-compose up`

2. Connect to the local mongo server at http://localhost:8081

Create a new db, hsm_develop

3. Start the seed container

```
docker-compose run --rm mongo-seed
```

4. Issue (in the shell)

```
mongo mongodb://mongodb:27017/admin -u root -p example
```
then create the hsm_develop user and grant it access:

```
db.createUser({ user: 'hsm_develop', pwd: 'hsm_develop', roles: [ { role: "readWrite", db: "hsm_develop" }]})
```

5. Download one of the dumps from /retina/backups on the troupeit production host.

6. Load the dump - I used user root and password example for this. This renames the db from hsm_production to hsm_develop during the ingest.

```
mongorestore --nsInclude hsm_production.\* --nsFrom "hsm_production.*" --nsTo "hsm_develop.*" mongodb://root@mongodb:27017 dump

```

8. add a user from the mongo-seed container
  
```
db.createUser({ user: "hsm_develop", pwd: "hsm_develop", roles: [ { role: "readWrite", db: "hsm_develop" } ]})
```

Major changes
-------
ActsAsTaggable not supported in Rails 8 - Moving to gem 'acts-as-taggable-on' with the
following setup:

```
rake acts_as_taggable_on_engine:install:migrations
rake db:migrate
```


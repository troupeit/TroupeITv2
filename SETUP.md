TroupeIT V2 MongoDB Migration
----------
Notes: 

* We are running mongo version 3.x in prod. 
* We want to get up to monogdb version 7 or better.
* The upgrade process is 5 -> 6 -> 7
* This work only gets us to version 5 -- going to stop there for now.

## Build Ruby First

First you'll need a working copy of Ruby. We are using 3.3.6.
Building this with openssl and arm leads to all sorts of problems.
We are dping:

```
rvm install 3.3.6 --with-openssl-dir=$(brew --prefix openssl)
```

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

Other notes
-------
Once the mongodb database is running in docker, it can be exported via:

```
mkdir backup
docker run --rm --volumes-from troupeitv2-mongodb-1 -v `pwd`:/backup ubuntu tar cvf /backup/backup.tar /data
```

And then you can restore that volume again into a newly started mongodb container.
We should move this to a bind-mount as container-volumes are a real pain to manage.

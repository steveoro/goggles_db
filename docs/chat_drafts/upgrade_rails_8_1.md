[2026-03-27] Starting request:
We need a detailed migration plan to Rails 8.1+ for the whole Goggles Framework. Start focusing just on goggles_db.
The plan needs to be detailed and allow several sprints to be spread out across several days of work. Store the plan on the branch so that we can resume it across machines. Prefer using the graph_mem toolset over storing static memories on the current localhost as graph_mem can export and restore DB dumps more easily than choosing and copying over memory files. If you store any data on the graph_mem DB, it will be the developer responsibility to carry over the DB instance across different machines for seamless work context continuity.
We must also keep up-to-date the CircleCI pipeline (@config.yml ).
We'll work specifically on the current branch only ('rails-8.1').
Use @replan @goggles-engine-update @goggles-data-model @goggles-db-patterns @goggles-db-scenic-view @goggles-overview and any other skill you might find useful.
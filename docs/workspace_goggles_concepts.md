# Goggles Workspace Operating Principles
The following section is a very high-level description of the workspace parts. Consider this as a work-in-progress.
Much of the points below may still be subject to change and surely need more details and explanations.

## Workspace "Bird's Eye View"
Goggles is a swimming competition results aggregator. It is composed of a main front-end (or client) web app and an administration web app.

The main client is deployed on a remote server; the admin client is used only locally.
Although both applications have an imperative multi-locale support, data is currently extracted only from the Italian Master Swimming Federation for ease of maintenance.
(There is only 1 maintainer, which is also the main developer.)
Being a very specific domain application, further details may be required to better understand its operating principles.

## Data flow
- The main client (deployed on remote) is read-only.
- The admin client (run and used only locally) is read-write.
- The API backend (deployed on remote) is read-write and is used by the both the main UI client and the admin client for data synchronization and exchange.
- The main UI client and the API share the same physical database and models by using the same database engine as a gem dependency.
- The local admin client reuses the same database engine gem (so, same structure and models), but works on a localhost copy of the same remote database.

### Actual flow:
1. data import (local admin client)
2. data review and manual adjustment (local admin client)
3. data exchange (local -> remote, via API)


## Data description
Each swimming competition is usually held in "Meetings". Each Meeting may hold several Events.
Each Event will have its own results, divided according to type of event, age and gender of the swimmer.
Swimmer age is grouped in range of 5 years, usually starting a 20+ years of age.
Swimmers are so categorized as "M<XX>" where "M" stands for "Master" and <XX> stands for the starting age group. (Example: "M35" corresponds to any swimmer aged 35..39)
So the swimmer category evolves with time and meeting results are relative to the year in which the meeting was held.

Swimming competition results are published online a few days after the end of a Meeting, on the web pages associated with the Swimming Federation that started the Championship in which the Meeting is held.
These pages usually need to be crawled or read from time to time In order to acquire and aggregate all meeting results found available.
Unfortunately, published data does not have always a standard format and a huge deal of the "data-import" work revolves around data conversion and parsing into a common format.
Data acquired this way is inherently error-prone and needs at most human confirmation for detecting or fixing any possible flaws, such as misnaming, misidentifying fields or wrong value attribution during parsing.

Once the data is successfully parsed and acquired locally, the admin interface can communicate with the remote host via an API to send data updates.
The remote main client is mostly read-write and works essentially as a "swimming results browser". Most of the data updates are only performed locally through the Admin interface.

## Framework parts and objectives
When referred as a framework, Goggles is composed of these projects:

1. `goggles_db.wiki`: the framework wiki where all technical details are documented in Markdown.
  - a.k.a. "the Wiki"
  - may contain some outdated info that needs to be updated sooner or later

2. `goggles_db`: a namespaced Rails Engine storing the whole database structure for Goggles with its models, most of its Business Logic, several strategy classes and "data-oriented" decorators.
  - a.k.a. the "DB", includes all database models and most of the Business Logic reused in goggles_main, goggles_api and goggles_admin2 as a gem dependency.
  - the database defined herein is reused in all other parts of the framework

3. `goggles_api`: a stand-alone Rails application that holds all the API endpoints with JWT-based authentication.
  - a.k.a. the "API"

4. `goggles_main`: a stand-alone Rails application that implements the main front-end UI.
  - a.k.a. "Main" app
  - deployed on a remote server as a composed Docker container running the DB, the API and the Main UI
  - coding-wise, +includes some front-end specific decorators and components; some of these objects are copied over to "Admin2" and customized according to the specific needs of Admin2 (which uses both a local DB and a remote, API-based DB)

5. `goggles_admin2`: a stand-alone Rails application that implements an admin web interface for managing the database and importing new data sets.
  - a.k.a. "Admin" or "Admin2" app
  - to be run or deployed only locally (mostly for security reasons)
  - allows to access data from a local copy of the DB and to compare and exchange data with the remote API endpoints (which are using their own copy of the DB)
  - contains a Node JS server application with its own API endpoints that allow control of a web crawler using Puppeteer; a.k.a. as the "data crawler" (of the framework)
  - contains an internal PDF parser ("Pdf::FormatParser") and format converter written in Ruby that allows to parse the most common format layouts used in some of the data downloaded with the crawler

### 5.1 The "Data Crawler" (inside Admin2):
- is currently able to extract data from 2 different categories of web pages:
  - an "event calendar" page, listing all planned meetings;
  - a "result page", listing all results for a single meeting;

- each meeting after its completion will usually yield a working link to a dedicated result page, which will be then crawled for results extraction.
- the data on the crawled page can be represented either as text, and thus easily converted into a JSON format for data acquisition, or could be sometimes just available as downloadable PDF file, requiring then a different process altogether for data acquisition.
- in order to fully process data downloaded as a PDF file, Admin2 needs to:
  - convert the PDF into a text file
  - identify and parse the specific layout format of the data stored inside the PDF file (and each PDF file can have multiple layout formats for each page)
  - use the bespoke "FormarParser" to parse and convert each custom layout into a common format for ease of data acquisition

### 5.2 The "FormarParser" used for PDFs converted to TXT (part of Admin2):
- defines several "families" of layout formats using YAML files with a specific naming convention (the first part of the filename before a '.' is the name of the parent format)
- scans the TXT data file obtained from the PDF result file (converted with a simple 'pdf2txt' bash command).
- each existing YAML format file found is checked until a match is found; when a matching member of a format family is found, only the subformats belonging to the same family will be checked for a match.
- the parsing of the data layout carries on for every result event subtable represented on the PDF, page by page.
- the parsing is successfull only if all the pages of the source TXT file have been identified in format and extracted.


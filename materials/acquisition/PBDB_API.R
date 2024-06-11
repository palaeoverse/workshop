################################################################################
#                                                                              #
#                  Practical - Sourcing palaeobiological data                  #
#                                                                              #
#                               Bethany Allen                                  #
#           Based on an earlier tutorial co-written with Graeme Lloyd          #
#                                                                              #
################################################################################

# SCRIPT AIMS:
# 1. Introduce the PBDB API.
# 2. Download a dataset.
# 3. Explore the dataset and identify some potential issues for conducting data
#     analysis.

# We will be using dplyr to manipulate our data, so we need to download it...
utils::install.packages("dplyr", dependencies = TRUE)

# ... and load it into memory:
library(dplyr)

# To access our fossil data, we are going to take advantage of the Paleobiology
# Database's "API" (short for Application Programming Interface), which lets us
# "download" data directly into R. We are going to download a dataset of canids
# (dogs) from the Neogene.
#
# We can begin by setting up some variables:
Taxa <- "Canidae" # Set "Taxa" as the taxonomic group of interest
StartInterval <- "Miocene" # Set start interval for sampling window
StopInterval <- "Pliocene" # Set stop interval for sampling window

# In case you want to alter these for your own purposes, you should also run
# the following lines which will ensure things get formatted properly for use
# with the API:
Taxa <- paste(Taxa, collapse = ",")
StartInterval <- gsub(" ", "%20", StartInterval)
StopInterval <- gsub(" ", "%20", StopInterval)

# We are now ready to use the API, but to do that we have to produce a
# formatted URL (Uniform Resource Locator; i.e., a web address). You will
# therefore need an internet connection to run the rest of this script.
#
# These will always begin with:
"https://paleobiodb.org/data1.2"

# This is simply the top-level of the database, with 'data1.2' indicating that
# we are using version 1.2 (the latest version) of the API.
# 
# Next we want the type of query, here we want some fossil occurrences (which is
# what most queries are going to be). Here we are going to ask for them as a CSV
# (comma-separated values):
"https://paleobiodb.org/data1.2/occs/list.csv"

# It is important to note that this means R will assume any comma it finds
# in the output represents a division between columns of data. If any of the
# data fields we want to output contain a comma, things are going to break, and
# hence why other formats (e.g., JSON) are also available. Here we should be
# fine though.
#
# Next we need to tell the database what taxon we actually want data for, so
# we can use our Taxa variable from above with:
paste0("https://paleobiodb.org/data1.2/occs/list.csv?base_name=", Taxa)

# The next thing to do is add any additional options we want to add to our
# query. The obvious one here is the sampling window. We can do this with the
# interval= option and as this is an addition to the query we proceed it with an
# ampersand (&):
paste0("https://paleobiodb.org/data1.2/occs/list.csv?base_name=", Taxa,
  "&interval=", StartInterval, ",", StopInterval)

# Note that the start and end of the interval have to be separated by a comma.
#
# We can now add some additional options for what we want the output to include
# with show=. If you want multiple things, again, these must be separated by
# commas. Here we will ask for coordinate data (coords), locality data (loc),
# taxonomic hierarchy data (class) and stratigraphic information (strat):
paste0("https://paleobiodb.org/data1.2/occs/list.csv?base_name=", Taxa,
  "&interval=", StartInterval, ",", StopInterval,
  "&show=coords,loc,class,strat")

# (Note: for a full list of all the options you should consult the API
# documentation at: https://paleobiodb.org/data1.2/.)
#
# One final tip is to make sure you only get "regular" taxa and not something
# from a parataxonomy (like egg or footprint "species") with the pres= option
# and the value "regular":
paste0("https://paleobiodb.org/data1.2/occs/list.csv?base_name=", Taxa,
  "&interval=", StartInterval, ",", StopInterval,
  "&show=coords,loc,class,strat&pres=regular")

# Now we have a complete URL we can store it in a variable...:
URL <- paste0("https://paleobiodb.org/data1.2/occs/list.csv?base_name=",
  Taxa, "&interval=", StartInterval, ",", StopInterval,
  "&show=coords,loc,class,strat&pres=regular")

# ...and then use the read.csv function to read the data into R:
RawData <- utils::read.csv(URL, header = TRUE, stringsAsFactors = FALSE)

# To see the number of occurrences we can ask for the number of data frame rows:
nrow(RawData)

# For a better idea of the contents, we can view the column names and top few
# rows of data:
head(RawData)

# You should never take a raw data query like these and use it without some kind
# of scrutiny. There could be all sorts of mistakes or things you don't intend
# in the dataset. For example, things can go wrong if names are duplicated in
# the database. An example is the genus "Glyptolepis" which is both a plant
# (type of conifer)...:
utils::browseURL("https://paleobiodb.org/classic/basicTaxonInfo?taxon_no=291933")

# ...and a fish (lobe-fin):
utils::browseURL("https://paleobiodb.org/classic/basicTaxonInfo?taxon_no=34920")

# Thus if we ask the database for Glyptolepis, the response might not be what we
# expect. Let's skip ahead and ask for this data to see what happens:
utils::read.csv("https://paleobiodb.org/data1.2/occs/list.csv?base_name=Glyptolepis&show=coords,paleoloc,class&limit=all", header = T, na.strings = "")

# Instead of an error message (there are two Glyptolepises!) the API just
# goes with one of them (the fish). Note this is not happening because
# there are no occurrences of the plant in the database. We can check that
# this is true by asking for the plant Glyptolepis with:
utils::read.csv("https://paleobiodb.org/data1.2/occs/list.csv?taxon_id=291933&show=coords,paleoloc,class&limit=all",
                header = T, na.strings = "")

# Thus if you *really* want to be sure you are getting the data you want you
# should use taxon_id= and the taxon number, and not base_name= and the taxon
# name. Remember that the ICZN and ICBN are separate entities so there is
# nothing to stop people naming a group of plants and a group of animals the
# same name!

# We will now take a look at the taxonomic contents of our dataset via the
# 'accepted_name' column. This gives us the identifications of our occurrences
# including any taxonomic updates (e.g. synonymisations, species transferred to
# different genera, *nomen dubia*) recorded in the PBDB.
unique(RawData$accepted_name)

# Do you notice anything concerning? Perhaps not at first glance, but what about
# this?
grep("ferox", unique(RawData$accepted_name))

# Two species are listed with the name 'ferox'. We can see their full names by
# merging the two lines above:
unique(RawData$accepted_name)[grep("ferox", unique(RawData$accepted_name))]

# Are these different species which were both named 'ferox', or are they the
# same species which has been transferred between genera, and the PBDB has
# failed to collapse them together?
# If we look at their full taxon pages, we can see that were named by different
# authors, and are in fact fully independent species:
utils::browseURL("https://paleobiodb.org/classic/basicTaxonInfo?taxon_no=43762")
utils::browseURL("https://paleobiodb.org/classic/basicTaxonInfo?taxon_no=44840")

# Otherwise, the dataset meets our expectations, so we will continue to
# explore the data a little more.
#
# It's good practice to save your download for posterity. First you will need
# to set a working directory - this tells R where to save your file (and look
# for files you want to load into R). This requires a file path to the folder
# you want to use, e.g. to save to the desktop in Windows you would use:
setwd("C:/Users/PCname/Desktop")

# You can find the file path of a folder by looking at its properties, but
# make sure you use forward slashes ( / ) and the same capitalisation. If
# you run this line and get no response in the console, it has worked.

# You can easily save a .csv using:
write.csv(RawData, file = "Neogene_Canidae.csv")

# The text in quotes specifies the file name.
#
# If you want to pull this saved dataset back into R at a later date, you
# can use:
RawData <- read.csv("Neogene_Canidae.csv")

# So, now to actually start manipulating our dataset.
# First we will simply trim the database fields (columns) to the ones we 
# really want:
RawData <- dplyr::select(RawData, c("occurrence_no", "collection_no", "phylum",
                             "class", "order", "family", "genus",
                             "accepted_name", "early_interval",
                             "late_interval", "max_ma", "min_ma", "lng", "lat",
                             "cc", "state", "identified_rank", "formation"))

# A key issue which could be important to our analysis pipeline is that our
# fossils are identified to a range of taxonomic resolutions:
count(RawData, identified_rank)

# Another issue to consider is that synonymisation of taxa in the PBDB can lead
# to separate entries with the same name (as junior synonyms are replaced with
# their senior counterparts). If you want to know about richness this is an
# issue, as it artificially inflates your estimate.
# We can stop this from happening by stripping out combinations of the same
# accepted name and collection number (a collection is somewhat analogous to a
# fossil locality).
RawData <- dplyr::distinct(RawData, accepted_name, collection_no,
  .keep_all = TRUE)

# Now that this is done, we can see the abundance distribution of genera in the
# dataset:
count(RawData, genus)

# Why is the first row blank? These are our occurrences which are identified to
# a more coarse resolution than genus.
#
# We can also take a look at the named earliest time intervals for our
# occurrences:
count(RawData, early_interval)

# Many of the names given are from the North American land mammal scheme, such
# as 'Clarendonian' and 'Hemphillian', with some variation as to the temporal
# resolution. This could make comparison of the ages of these fossils quite
# tricky.
#
# Does this also mean that our fossils have a strong geographic bias? We can
# check that by looking at the "cc" column, which contains the country code of
# the locality:
count(RawData, cc)

# It seems so! Almost all of our occurrences are from the USA ('US'), although
# many other countries are also represented in the list.
#
# Here we have briefly explored some of the features of a standard Paleobiology
# Database occurrence dataset, and highlighted some potential issues. Next we
# will discuss some approaches for cleaning up such a dataset ready for
# analysis.

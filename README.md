# Disclaimer

This tool is made available for the convenience of the Washington Community and
Technical College System. Bellevue College does not support, warranty or assist
in the use of the tool.

[David Mielcarek, 20150817] Added PDF detailing installation/configuring (25LiveInterface-manual.pdf).
Added Head Count add-on (see 25LiveUSPHeadCount Web.config Key/Value).

[David Mielcarek, 20150806] Regarding this project, and the upgrades/add-ons below,
I am available for assistance if needed.  I will include a PDF detailing the steps
LCC performed to install the project, including errors/suggestion (all of which are
addressed/fixed in the upgraded version).   The file is:
* projectPlan-2015-002-25Live-snippetOnly-25LiveInterface.pdf

[David Mielcarek, 20150806] I have added the following upgrades to the project:
* all values externalized to Web.config (like the 'usp' procedure name)
* logging now happens throughout
* log levels are now defined in the Web.config, which allows control of what gets logged
* a log level has been defined to 'skip' the actual SQL call, this allows for very quick
testing/debugging, especially on installation
* all code issues have been resolved
Version is now stable/generalized that should work with any college.

[David Mielcarek, 20150806] Added a new set of tools (lccToolsClass):
* lccFTranslateId: translates SMS Location Ids into PeopleSoft Ids
* lccFLoadTranslationPairs: loads translation pairs from external (tab delimited) file
* lccFLogInfo: logging, log record syntax: [date] [time] [Requestor IP] [Call Id] [Log Level] [...info...]
* lccSettingsClass: global settings for cross function/class use

# Project Overview

The goal of this project is to provide an auto generated file (based on the
given configurations) that act as an input to 25Live software, which will be
used to automate the process of scheduling rooms on campus.

## Software

* Microsoft .Net Framework 4.5
* IIS 7.5
* Visual Studio 2013
    * C#
    * EntityFramework 6.0

## Feature Set

   1. Use a URL format like for eg: http://domainname/../CreateDatain/CreateNewFile/B561 to run the script that creates            Datain file named as defined in the config concatenated with the Year Quarter.
   1. You can change the yearQuarter in the url above to create datain for a particular quarter.
   1. Move existing file into Archive (rename it to originalName+Timestamp).
   1. Scheduled task to automatically run the application for a given quarter.
   1. Translating SMS Location Ids to PeopleSoft Ids.  Syntax of Translation file should be:
       * [SMS Location Id] [tab] [PeopleSoft Id]
	   * Ex: AAR 101 [tab] LCC001AAR0101

## Configuration

Please refer web.config-template file.

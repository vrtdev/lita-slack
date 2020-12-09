# Changelog

All notable changes to this project will be documented in this file.

Version format based on <http://semver.org/>

## [Unreleased]

### Changed

- Deprecated API method im_open replaced by conversations_open
- Deprecated API method groups_info replaced by conversations_info
- Deprecated API method channels_info replaced by conversations_info
- Deprecated API method channels_list replaced by 
- Deprecated API method groups_list replaced by 
- Deprecated API method mpim_list replaced by 
- Deprecated API method im_list replaced by 

## [2.0.0.0] - 2020-10-29

Using v 2 to indicate this is no longer the https://github.com/litaio/lita-slack version
### Added

- send_file method

## [1.9.0.1] - 2020-10-29

### Changed

- Strip Now break spaces in message texts
- Add API methods for identifying private chats
  - channel_info: Deprecated API, will need to be removed soon.
  - group_info : Deprecated API, will need to be removed soon.
  - conversation_info : New API, can remain

## [0.1.0] - 2020-01-13

### Added

- ...

### Changed

- ...

### Removed

- ...

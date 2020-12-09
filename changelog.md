# Changelog

All notable changes to this project will be documented in this file.

Version format based on <http://semver.org/>

## [Unreleased]

## [2.1.0.0] - 2020-12-09

### Changed

- Deprecated method im_open replaced by conversations_open
- Deprecated method groups_info replaced by conversations_info
- Deprecated method channels_info replaced by conversations_info
- Deprecated API method channels.list replaced by conversations.list
- Deprecated API method groups.list replaced by conversations.list
- Deprecated API method mpim.list replaced by conversations.list
- Deprecated API method im.list replaced by conversations.list
- Deprecated API method channels.setTopic replaced by conversations.setTopic

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

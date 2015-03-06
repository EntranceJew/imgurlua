imgurlua
========
*This is not 100%*, I just uploaded it to get some eyes on it. It is intended to be an identical recreation of 
[imgurpython](https://github.com/Imgur/imgurpython) but naturally some things will probably fall through the cracks
at this time.

A Lua client for the [Imgur API](http://api.imgur.com/). It can be used to
interact with the Imgur API in your projects.

You must [register](http://api.imgur.com/oauth2/addclient) your client with the Imgur API, and provide the Client-ID to
make *any* request to the API (see the [Authentication](https://api.imgur.com/#authentication) note). If you want to
perform actions on accounts, the user will have to authorize your application through OAuth2.

Requirements
------------
Most of these libraries are currently included in the repo, however, dependencies will eventually be phased out to increase portability.
- Lua >= 5.1
- [jf-JSON](http://regex.info/blog/lua/json)
- [lume](https://github.com/rxi/lume/)
- [middleclass](https://github.com/kikito/middleclass)
- [LuaSec](http://love2d.org/forums/viewtopic.php?f=5&t=76728)

Imgur API Documentation
-----------------------

Their developer documentation can be found [here](https://api.imgur.com/).

Community
---------

The best way to reach out to Imgur for API support would be their
[Google Group](https://groups.google.com/forum/#!forum/imgur), [Twitter](https://twitter.com/imgurapi), or via
 api@imgur.com. However, if it's a lua error you're having, EntranceJew is the guy you're going to want to talk to.

Installation
------------

    download it, rockspecs are confusing and I'm not ready for them yet

Library Usage
------------

Using imgurlua in your application takes just a couple quick steps.

To use the client from a strictly anonymous context (no actions on behalf of a user)

```lua

require("lib") 
--this is only like this because I kept the testing app inside the repo, this will be fixed

client_id = 'YOUR CLIENT ID'
client_secret = 'YOUR CLIENT SECRET'

client = ImgurClient(client_id, client_secret)

-- Example request
items = client:gallery()
for _,item in pairs(items) do
    print(item.link)
end

```

### Error Handling
Anything that was explicitly handled by imgurpython is asserted in imgurlua, 
plus some assertions that certain arguments be provided to methods.

### Credits

To view client and user credit information, use the `credits` attribute of `ImgurClient`.
`credits` holds a table with the following keys:
* UserLimit
* UserRemaining
* UserReset
* ClientLimit
* ClientRemaining

For more information about rate-limiting, please see the note in their [docs](http://api.imgur.com/#limits)!

Examples
------------
Running this repo in love2d is its own example.

## ImgurClient Functions

### Account

* `get_account(username)`
* `get_gallery_favorites(username)`
* `get_account_favorites(username)`
* `get_account_submissions(username, page=0)`
* `get_account_settings(username)`
* `change_account_settings(username, fields)`
* `get_email_verification_status(username)`
* `send_verification_email(username)`
* `get_account_albums(username, page=0)`
* `get_account_album_ids(username, page=0)`
* `get_account_album_count(username)`
* `get_account_comments(username, sort='newest', page=0)`
* `get_account_comment_ids(username, sort='newest', page=0)`
* `get_account_comment_count(username)`
* `get_account_images(username, page=0)`
* `get_account_image_ids(username, page=0)`
* `get_account_album_count(username)`

### Album
* `get_album(album_id)`
* `get_album_images(album_id)`
* `create_album(fields)`
* `update_album(album_id, fields)`
* `album_delete(album_id)`
* `album_favorite(album_id)`
* `album_set_images(album_id, ids)`
* `album_add_images(album_id, ids)`
* `album_remove_images(album_id, ids)`

### Comment
* `get_comment(comment_id)`
* `delete_comment(comment_id)`
* `get_comment_replies(comment_id)`
* `post_comment_reply(comment_id, image_id, comment)`
* `comment_vote(comment_id, vote='up')`
* `comment_report(comment_id)`

### Custom Gallery

* `get_custom_gallery(gallery_id, sort='viral', window='week', page=0)`
* `get_user_galleries()`
* `create_custom_gallery(name, tags=None)`
* `custom_gallery_update(gallery_id, name)`
* `custom_gallery_add_tags(gallery_id, tags)`
* `custom_gallery_remove_tags(gallery_id, tags)`
* `custom_gallery_delete(gallery_id)`
* `filtered_out_tags()`
* `block_tag(tag)`
* `unblock_tag(tag)`

### Gallery

* `gallery(section='hot', sort='viral', page=0, window='day', show_viral=True)`
* `memes_subgallery(sort='viral', page=0, window='week')`
* `memes_subgallery_image(item_id)`
* `subreddit_gallery(subreddit, sort='time', window='week', page=0)`
* `subreddit_image(subreddit, image_id)`
* `gallery_tag(tag, sort='viral', page=0, window='week')`
* `gallery_tag_image(tag, item_id)`
* `gallery_item_tags(item_id)`
* `gallery_tag_vote(item_id, tag, vote)`
* `gallery_search(q, advanced=None, sort='time', window='all', page=0)`
* `gallery_random(page=0)`
* `share_on_imgur(item_id, title, terms=0)`
* `remove_from_gallery(item_id)`
* `gallery_item(item_id)`
* `report_gallery_item(item_id)`
* `gallery_item_vote(item_id, vote='up')`
* `gallery_item_comments(item_id, sort='best')`
* `gallery_comment(item_id, comment)`
* `gallery_comment_ids(item_id)`
* `gallery_comment_count(item_id)`

### Image

* `get_image(image_id)`
* `upload_from_path(path, config=None, anon=True)`
* `upload_from_url(url, config=None, anon=True)`
* `delete_image(image_id)`
* `favorite_image(image_id)`

### Conversation

* `conversation_list()`
* `get_conversation(conversation_id, page=1, offset=0)`
* `create_message(recipient, body)`
* `delete_conversation(conversation_id)`
* `report_sender(username)`
* `block_sender(username)`

### Notification

* `get_notifications(new=True)`
* `get_notification(notification_id)`
* `mark_notifications_as_read(notification_ids)`

### Memegen

* `default_memes()`

Imgur entry points
==================
| entry point                         |  content                       |
|-------------------------------------|--------------------------------|
| imgur.com/{image_id}                | image                          |
| imgur.com/{image_id}.extension      | direct link to image (no html) |
| imgur.com/a/{album_id}              | album                          |
| imgur.com/a/{album_id}#{image_id}   | single image from an album     |
| imgur.com/gallery/{gallery_post_id} | gallery                        |

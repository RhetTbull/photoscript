-- TODO: Variable names are not very consistent throughout this

---------- PhotoLibrary ----------
on _activate()
	(* activate Photos app *)
	tell application "Photos"
		activate
	end tell
end _activate

on _quit()
	(* quit Photos app *)
	tell application "Photos"
		quit
	end tell
end _quit

on _photoslibrary_name()
	(* name of application *)
	tell application "Photos"
		return name
	end tell
end _photoslibrary_name

on _photoslibrary_version()
	(* Photos version *)
	tell application "Photos"
		return version
	end tell
end _photoslibrary_version

on _photoslibrary_frontmost()
	(* returns true if front most app, otherwise false *)
	tell application "Photos"
		return frontmost
	end tell
end _photoslibrary_frontmost

on _photoslibrary_get_all_photos()
	(* return all photos in the library *)
	set ids to {}
	tell application "Photos"
		repeat with _item in every media item
			copy id of _item to end of ids
		end repeat
	end tell
	return ids
end _photoslibrary_get_all_photos

on _photoslibrary_search_photos(search_str)
	(* search for photos by text string *)
	set ids to {}
	tell application "Photos"
		set _items to search for search_str
		repeat with _item in _items
			copy id of _item to end of ids
		end repeat
	end tell
	return ids
end _photoslibrary_search_photos

on _import(filenames, skip_duplicate_check)
	(* import files
	   Args:
	       filenames: list of files in POSIX format to import
		skip_duplicate_check: boolean, if True, skips checking for duplicates
	*)
	set file_list to {}
	repeat with f in filenames
		set fname to POSIX file f
		copy fname to the end of file_list
	end repeat
	tell application "Photos"
		import file_list skip check duplicates skip_duplicate_check
	end tell
end _import

on _import_to_album(filenames, album_, skip_duplicate_check)
	(* import files into album 
	   Args:
	       filenames: list of files in POSIX format to import
	       album_name: name of album to import to
		skip_duplicate_check: boolean, if True, skips checking for duplicates
	*)
	set file_list to {}
	repeat with f in filenames
		set fname to POSIX file f
		copy fname to the end of file_list
	end repeat
	tell application "Photos"
		import file_list into album id (album_) skip check duplicates skip_duplicate_check
	end tell
end _import_to_album

on _album_names(top_level)
	(* return list of album names found in Photos *)
	if top_level then
		
		tell application "Photos"
			return name of every album
		end tell
	else
		set albums_folders to _get_album_folder_names()
		return album_names of albums_folders
	end if
end _album_names

on _folder_names(top_level)
	(* return list of folder names found in Photos *)
	if top_level then
		tell application "Photos"
			return name of every folder
		end tell
	else
		set albums_folders to _get_album_folder_names()
		return folder_names of albums_folders
	end if
	
end _folder_names

on _get_albums_folders()
	(* return record containing album names and folder names in the library
	
	    Returns: {album_names:list of album names, folder_names:list of folder names}
	*)
	# see https://discussions.apple.com/docs/DOC-250002459
	tell application "Photos"
		set allfolders to {}
		set allalbums to the albums --  collect all albums
		set level to 0 -- nesting level of folders
		
		set nextlevelFolders to the folders
		set currentLevelFolders to {}
		
		repeat while (nextlevelFolders is not {})
			set currentLevelFolders to nextlevelFolders
			set nextlevelFolders to {}
			repeat with fi in currentLevelFolders
				tell fi
					set ffolders to its folders
					set falbums to its albums
					set nextlevelFolders to ffolders & nextlevelFolders
					set allalbums to falbums & allalbums
				end tell
			end repeat
			set allfolders to currentLevelFolders & allfolders
			
			set level to level + 1
		end repeat
	end tell
	
	set albums_folders to {_albums:allalbums, _folders:allfolders}
	return albums_folders
end _get_albums_folders

on _get_album_folder_names()
	(* return names of albums and folders *)
	set albums_folders to _get_albums_folders()
	set allalbums to _albums of albums_folders
	set allfolders to _folders of albums_folders
	set allalbumnames to {}
	set allfoldernames to {}
	tell application "Photos"
		
		repeat with _album in allalbums
			set theName to name of _album
			copy theName to end of allalbumnames
		end repeat
		repeat with _folder in allfolders
			set theName to name of _folder
			copy theName to end of allfoldernames
		end repeat
	end tell
	set album_folder_names to {album_names:allalbumnames, folder_names:allfoldernames}
	return album_folder_names
end _get_album_folder_names

on _album_ids(top_level)
	(* return list of album ids found in Photos 
	  Args:
	      top_level: boolean; if true returns only top-level albums otherwise all albums
	*)
	if top_level then
		tell application "Photos"
			return id of every album
		end tell
	else
		set albums_folders to _get_albums_folders()
		set _albums to _albums of albums_folders
		set _ids to {}
		repeat with _a in _albums
			copy id of _a to end of _ids
		end repeat
		return _ids
	end if
end _album_ids

on _create_album(albumName)
	(*  creates album named albumName
	     does not check for duplicate album
           Returns:
		    UUID of newly created album 
	*)
	tell application "Photos"
		set theAlbum to make new album named albumName
		set theID to ((id of theAlbum) as text)
		return theID
	end tell
end _create_album

on _get_selection()
	(* return ids of selected items *)
	set item_ids_ to {}
	tell application "Photos"
		set items_ to selection
		repeat with item_ in items_
			copy id of item_ to end of item_ids_
		end repeat
	end tell
	return item_ids_
end _get_selection

on _photoslib_favorites()
	(* return favorites album *)
	tell application "Photos"
		return id of favorites album
	end tell
end _photoslib_favorites

on _photoslib_recently_deleted()
	(* return recently deleted album *)
	tell application "Photos"
		return id of recently deleted album
	end tell
end _photoslib_recently_deleted

on _photoslib_delete_album(id_)
	(* delete album with id_ *)
	tell application "Photos"
		set album_ to album id (id_)
		delete album_
	end tell
end _photoslib_delete_album

---------- Album ----------

on _album_name(_id)
	(* return name of album with id _id *)
	tell application "Photos"
		return name of album id (_id)
	end tell
end _album_name

on _album_by_name(_name)
	(* return album id of album named _name or 0 if no album found with _name
	    if more than one album named _name, returns the first one found 
	*)
	set albums_folders to _get_albums_folders()
	set _albums to _albums of albums_folders
	repeat with _a in _albums
		if name of _a = _name then
			return id of _a
		end if
	end repeat
	return 0
end _album_by_name

on _album_exists(_id)
	(* return true if album with _id exists otherwise false *)
	tell application "Photos"
		try
			set _exist to album id (_id)
		on error
			return false
		end try
		
		return true
	end tell
end _album_exists

on _album_parent(_id)
	(* returns parent folder id of album or 0 if no parent *)
	try
		tell application "Photos"
			return id of parent of album id (_id)
		end tell
	on error
		return 0
	end try
end _album_parent

on _album_photos(id_)
	(* return list of ids for media items in album _id *)
	set ids to {}
	tell application "Photos"
		set _album to album id (id_)
		set _items to media items of _album
		repeat with _item in _items
			copy id of _item to end of ids
		end repeat
	end tell
	return ids
end _album_photos

on _album_len(id_)
	(* return count of items in albums *)
	tell application "Photos"
		return count of media items in album id (id_)
	end tell
end _album_len

on _album_add(id_, items_)
	(* add media items to album
	    Args:
		id_: id of album
	       items_: list of media item ids
	*)
	tell application "Photos"
		set media_list_ to {}
		repeat with item_ in items_
			copy media item id (item_) to end of media_list_
		end repeat
		set album_ to album id (id_)
		add media_list_ to album_
	end tell
end _album_add

---------- Photo ----------
on _photo_exists(_id)
	(* return true if media item with _id exists otherwise false *)
	tell application "Photos"
		try
			set _exist to media item id (_id)
		on error
			return false
		end try
		
		return true
	end tell
end _photo_exists

on _photo_name(_id)
	(* name or title of photo *)
	tell application "Photos"
		return name of media item id (_id)
	end tell
end _photo_name

on _photo_description(_id)
	(* description of photo *)
	tell application "Photos"
		return description of media item id (_id)
	end tell
end _photo_description

on _photo_keywords(_id)
	(* keywords of photo *)
	tell application "Photos"
		return keywords of media item id (_id)
	end tell
end _photo_keywords

on _photo_date(_id)
	(* date of photo *)
	tell application "Photos"
		return date of media item id (_id)
	end tell
end _photo_date

on _photo_export(theUUID, thePath, original, edited, theTimeOut)
	(* export photo
	   Args:
	      theUUID: id of the photo to export
		  thePath: path to export to as POSIX path string
		  original: boolean, if true, exports original photo
		  edited: boolean, if true, exports edited photo
		  theTimeOut: how long to wait in case Photos timesout
	*)
	tell application "Photos"
		set thePath to thePath
		set theItem to media item id theUUID
		set theFilename to filename of theItem
		set itemList to {theItem}
		
		if original then
			with timeout of theTimeOut seconds
				export itemList to POSIX file thePath with using originals
			end timeout
		end if
		
		if edited then
			with timeout of theTimeOut seconds
				export itemList to POSIX file thePath
			end timeout
		end if
		
		return theFilename
	end tell
	
end _photo_export

on _photo_filename(id_)
	(* original filename of the photo *)
	tell application "Photos"
		return filename of media item id (id_)
	end tell
end _photo_filename

on _photo_duplicate(id_)
	tell application "Photos"
		set _new_photo to duplicate media item id (id_)
		return id of _new_photo
	end tell
end _photo_duplicate

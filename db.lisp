;; Copyright 2008 Josh Marchan

;; This file is part of sykosomatic

;; sykosomatic is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; sykosomatic is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with sykosomatic.  If not, see <http://www.gnu.org/licenses/>.

(in-package #:sykosomatic)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;========================================== Database ==========================================;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~~~~ Variables ~~~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defvar *player-ids* 0)
(defvar *room-ids* 0)

(defvar *articles* '("a" "an" "the"))
(defvar *nouns* nil)
(defvar *verbs* nil)
(defvar *adjectives* nil)
(defvar *adverbs* nil)
(defvar *prepositions* nil)
(defvar *pronouns* nil)

(defvar *directions* '("north" "south" "east" ;;necessary? I don't think so.
		       "west" "northeast" "northwest"
		       "southeast" "southwest" "up"
		       "down" "enter"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~ Load/Save ~~~~~~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defgeneric obj->file (obj path)
  (:documentation "Saves OBJECT to a file within PATH."))

(defun obj-list->files-in-dir (obj-list path)
  "Saves all OBJECTS in OBJECT-LIST into files within PATH"
  (loop for obj in obj-list
       do (obj->file obj path)))

(defun file->obj (filepath)
  "Takes the FILEPATH of a file, returns the OBJECT it represents."
  (cl-store:restore filepath))

(defun files-in-path->obj-list (path)
  "Takes -all- files in PATH and collects them into a LIST of OBJECTS."
  (let ((files (directory (merge-pathnames "*.*" path))))
    (loop for file in files
	 collect (cl-store:restore file))))

;; Some untidy saving/loading. Mostly temporary.
;; ---------------------------------------------
;
(defun save-vocabulary () ;; this stuff could go in the parser.
  "Saves all the nice vocabulary words :)"
  (cl-store:store *articles* (ensure-directories-exist (merge-pathnames #P"articles.db" *vocab-directory*)))
  (cl-store:store *nouns* (ensure-directories-exist (merge-pathnames #P"nouns.db" *vocab-directory*)))
  (cl-store:store *verbs* (ensure-directories-exist (merge-pathnames #P"verbs.db" *vocab-directory*)))
  (cl-store:store *adjectives* (ensure-directories-exist (merge-pathnames #P"adjectives.db" *vocab-directory*)))
  (cl-store:store *adverbs* (ensure-directories-exist (merge-pathnames #P"adverbs.db" *vocab-directory*)))
  (cl-store:store *prepositions* (ensure-directories-exist (merge-pathnames #P"prepositions.db" *vocab-directory*)))
  (cl-store:store *pronouns* (ensure-directories-exist (merge-pathnames #P"pronouns.db" *vocab-directory*))))

(defun load-vocabulary ()
  "Loads saved vocab files into their respective variables."
  (setf *articles* (cl-store:restore (merge-pathnames #P"articles.db" *vocab-directory*)))
  (setf *nouns* (cl-store:restore (merge-pathnames #P"nouns.db" *vocab-directory*)))
  (setf *verbs* (cl-store:restore (merge-pathnames #P"verbs.db" *vocab-directory*)))
  (setf *adjectives* (cl-store:restore (merge-pathnames #P"adjectives.db" *vocab-directory*)))
  (setf *adverbs* (cl-store:restore (merge-pathnames #P"adverbs.db" *vocab-directory*)))
  (setf *prepositions* (cl-store:restore (merge-pathnames #P"prepositions.db" *vocab-directory*)))
  (setf *pronouns* (cl-store:restore (merge-pathnames #P"pronouns.db" *vocab-directory*))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~ Utilities ~~~~~~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defun reset-player-ids ()
  (setf *player-ids* 0))

(defun reset-room-ids ()
  (setf *room-ids* 0))

(defun generate-test-players (num-players)
  "Returns a LIST containing NUM-PLAYERS instances of <player>."
  (loop for i upto (1- num-players)
       collect (new-player)))

(defun generate-test-rooms (num-rooms)
    "Returns a LIST containing NUM-ROOMS instances of <room>."
  (loop for i upto (1- num-rooms)
       collect (new-room)))

;; Utility vars
;; ------------
(defvar *rooms* nil)
(defvar *players* nil)
(defvar *objects* nil)
(defvar *vocabulary* nil)
(defvar *commands* nil)
(defvar *current-player* nil)
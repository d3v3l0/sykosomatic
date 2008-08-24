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

(in-package :sykosomatic)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;====================================== Player class ==========================================;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defclass <player> (<mobile>)
  ((desc
    :initform "This is a player.")
   (desc-long
    :initform "This is a player. It is quite handsome. ;)")
   (player-id
    :initarg :player-id
    :initform (incf *player-ids*)
    :reader player-id
    :documentation "A unique player id.")
   (current-client
    :initarg :current-client
    :initform nil
    :accessor current-client
    :documentation "The <client> currently associated with this <player>")))
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;================================= Player-related functions ===================================;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~ Player Generation ~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defun new-player ()
  "RETURNS a new PLAYER after initializing the <player> object"
  (let ((player (make-instance '<player>)))
    (with-accessors ((name name)) player
      (setf name (format nil "Player~d" (player-id player))))
    player))

(defmacro make-player (&key name desc desc-long features)
  `(make-instance '<player> :name ,name :desc ,desc :desc-long ,desc-long :features ,features))

(defun make-players-from-file (file)
  "Generates a player from a raw text FILE." ;; file generated by room-parse.lisp/.py
  (let ((players (with-open-file (in file)
		  (loop for line = (read in nil)
		     while line
		     collect line))))
    (loop for player in players
	 collect (eval player))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~~~~~~~~ Info ~~~~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defun player-p (obj)
  "Returns T if a given OBJ is an instance of <PLAYER>."
  (eq (class-name (class-of obj))
      '<player>))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~~~~ Load/Save ~~~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defmethod obj->file ((player <player>) path)
  (cl-store:store player (ensure-directories-exist
			  (merge-pathnames
			   (format nil "player-~a.player" (player-id player))
			   path))))

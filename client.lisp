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
;;;========================================== Client ============================================;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~~~~ Class ~~~~~~~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defclass <client> ()
  ((socket
    :initarg :socket
    :reader socket
    :initform nil
    :documentation "Socket belonging to this client.")
   (thread
    :initarg :thread
    :accessor thread
    :initform nil
    :documentation "Thread where everything related to this client resides.")
   (ip
    :initarg :ip
    :reader ip
    :initform nil
    :documentation "Client's IP address.")
   (last-active
    :initarg :last-active
    :initform (get-universal-time)
    :accessor last-active
    :documentation "Time when last input was received from client.")
   (account
    :initarg :account
    :accessor account
    :initform nil
    :documentation "The account associated with this session.")
   (avatar
    :initarg :avatar
    :accessor avatar
    :initform nil
    :documentation "The character linked to this client session.")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~~~~~ Connection ~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defun connect-new-client ()
  "Connects a new client to the main server."
  (let ((socket (usocket:socket-accept (socket *server*))))
    (let ((client (make-instance '<client>
				 :socket socket
				 :ip (usocket:get-peer-address socket))))
      (log-message :CLIENT (format nil "New client: ~a" (ip client)))
      (write-to-client client "Hello. Welcome to SykoSoMaTIC.~%")
      (push client (clients *server*)))))

(defun disconnect-client (client)
  "Disconnects the client and removes it from the current clients list."
  (write-to-client client "Disconnecting you, buh-bye~%")
  (with-accessors ((thread thread) (socket socket)) client
    (if socket
	(usocket:socket-close socket)
	(log-message :CLIENT-ERROR
		     (format nil "Error while disconnecting client ~a: No socket to close." (ip client))))
    (if thread
	(bordeaux-threads:destroy-thread thread)
	(log-message :CLIENT-ERROR
		     (format nil "Error while disconnecting client ~a: No thread to destroy." (ip client)))))
  (setf (clients *server*) (remove client (clients *server*))))

(defun client-idle-time (client)
  "How long, in seconds, since activity was last received from client."
  (- (get-universal-time) (last-active client)))

(defun update-activity (client)
  "Updates the activity time of client to now."
  (with-accessors ((activity last-active)) client
    (setf activity (get-universal-time))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~~~~ Client I/O ~~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;
;;        Input       ;;
;;;;;;;;;;;;;;;;;;;;;;;;
;
(defun read-line-from-client (client)
  "Grabs a line of input from a client. Takes care of stripping out any unwanted bytes."
  (handler-case
      (let* ((stream (usocket:socket-stream (socket client)))
	     (collected-bytes (loop with b
				 do (setf b (read-byte stream))
				 until (= b (char-code #\Newline))
				 unless (not (standard-char-p (code-char b)))
				 collect (code-char b))))
	(progn 
	  (update-activity client)
	  (coerce collected-bytes 'string)))
    (end-of-file () 
      (progn (log-message :CLIENT "End-of-file. Stream disconnected remotely.")
	     (disconnect-client client)))))

(defun prompt-client (client prompt-string)
  "Prompts a client for input"
  (write-to-client client prompt-string)
  (read-line-from-client client))

(defun client-y-or-n-p (client string)
  "y-or-n-p that sends the question over to the client."
  (write-to-client client string)
  (let ((answer (prompt-client client "(y or n)")))
    (cond ((string-equal "y" (char answer 0))
	   t)
	  ((string-equal "n" (char answer 0))
	   nil)
	  (t
	   (progn
	     (write-to-client client "Please answer y or n.~%")
	     (client-y-or-n-p client string))))))

;;;;;;;;;;;;;;;;;;;;;;;;;
;;        Output       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defun write-to-all-clients (format-string &rest format-args)
  "Sends a given string to all connected clients."
  (with-accessors ((clients clients)) *server*
    (mapcar #'(lambda (client) (write-to-client client format-string format-args)) clients)))

(defun write-to-client (client format-string &rest format-args)
  "Sends a given STRING to a particular client."
  (let ((string (apply #'format nil format-string format-args)))
    (handler-case 
	(let* ((stream (usocket:socket-stream (socket client)))
	       (bytes (loop for char across string
			 collect (char-code char))))
	  (loop for byte in bytes
	     do (write-byte byte stream)
	     finally (finish-output stream)))
      (simple-error () (log-message :CLIENT "Couldn't write to client"))
      (sb-int:simple-stream-error () (progn (log-message :CLIENT "Broken pipe, disconnecting client.")
					    (disconnect-client client))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~~~~~~~~ Main ~~~~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
(defun client-main (client)
  "Main function for clients."
  ) ;;Keep it simple at first. Grab input, echo something back.
;; Later on, allow clients to enter players, and run in the main player loop.
;; Then start getting fancy from there.

(defun player-main (client)
  "Main function for playing a character. Subprocedure of client-main"
  )
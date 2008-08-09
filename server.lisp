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
;;;=========================================== Server ===========================================;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~~~~~ Class ~~~~~~~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defclass <server> ()
  ((socket
    :accessor server-socket
    :initarg :server-socket)
   (clients
    :accessor clients
    :initform nil)
   (connection-thread
    :accessor connection-thread
    :initarg :connection-thread
    :documentation "Thread that runs the function to connect new clients.")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;~~~~~~~~~~~~~~~~~ Init/Destruct ~~~~~~~~~~~~~~;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
(defvar *default-server-address* "0.0.0.0")
(defvar *default-server-port* 4000)
(defvar *current-server* nil)

(defun start-server (&key (address *default-server-address*) (port *default-server-port*))
  (log-message :SERVER "Starting server...")
  (let* ((socket (usocket:socket-listen address port :reuse-address t :element-type '(unsigned-byte 8)))
	 (server (make-instance '<server>
				:server-socket socket)))
    (setf *current-server* server)
    (log-message :SERVER "Creating server connection thread.")
    (setf (connection-thread *current-server*) 
	  (bordeaux-threads:make-thread (lambda () 
					  (loop 
					     (handler-case (connect-new-client)
					       (sb-bsd-sockets:not-connected-error () 
						 (log-message :HAX "Hax0r be sappin' mah unconnected socket."))))) 
					:name "connector-thread"))
    (log-message :SERVER "Server started successfully.")))

(defun stop-server ()
  (if (not *current-server*)
      (log-message :SERVER "Tried to stop server, but no server running.")
      (progn
	(log-message :SERVER "Stopping server...")
	(log-message :SERVER "Disposing of clients.")
	(loop for client in (clients *current-server*)
	     do (usocket:socket-close (socket client)))
	(setf (clients *current-server*) nil)
	(log-message :SERVER "Clients removed.")
	(if (and (connection-thread *current-server*)
		 (bordeaux-threads:thread-alive-p (connection-thread *current-server*)))
	    (bordeaux-threads:destroy-thread (connection-thread *current-server*))
	    (log-message :SERVER "No thread running, skipping..."))
	(usocket:socket-close (server-socket *current-server*))
	(log-message :SERVER "Server stopped."))))
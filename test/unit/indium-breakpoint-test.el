;;; indium-breakpoint-test.el --- Test for indium-breakpoint.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2017  Nicolas Petton

;; Author: Nicolas Petton <nicolas@petton.fr>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'buttercup)
(require 'assess)
(require 'indium-breakpoint)

(describe "Accessing breakpoints"
  (it "can get a breakpoint overlays on the current line"
    (with-js2-buffer "let a = 1;"
      (let ((ov (make-overlay (point) (point))))
        (overlay-put ov 'indium-breakpoint t)
        (expect (indium-breakpoint-overlay-on-current-line) :to-be ov))))

  (it "can put a breakpoint on the current line"
    (with-js2-buffer "let a = 1;"
      (goto-char (point-min))
      (expect (indium-breakpoint-on-current-line-p) :to-be nil)
      (indium-breakpoint-add (make-indium-location))
      (expect (indium-breakpoint-on-current-line-p) :to-be-truthy)))

  (it "can edit a breakpoint on the current line"
    (spy-on #'read-from-minibuffer :and-return-value "new condition")
    (spy-on #'indium-breakpoint-remove :and-call-through)
    (spy-on #'indium-breakpoint-add :and-call-through)
    (with-js2-buffer "let a = 1;"
      (goto-char (point-min))
      (let ((location (make-indium-location :file buffer-file-name
					    :line 0)))
	(indium-breakpoint-add location "old condition")
	(indium-breakpoint-edit-condition)
	(expect #'read-from-minibuffer :to-have-been-called)
	(expect #'indium-breakpoint-remove :to-have-been-called)
	(expect #'indium-breakpoint-add :to-have-been-called-with location "new condition")))))

(describe "Breakpoint duplication handling"
  (it "can add a breakpoint multiple times on the same line without duplicating it"
    (with-temp-buffer
      (indium-breakpoint-add (make-indium-location))
      (let ((number-of-overlays (seq-length (overlays-in (point-min) (point-max)))))
        (indium-breakpoint-add (make-indium-location))
        (expect (seq-length (overlays-in (point-min) (point-max))) :to-equal number-of-overlays)))))

(describe "Restoring breakpoints"
  (it "can restore breakpoints from buffers when opening a new connection"
    (spy-on 'indium-backend-add-breakpoint)
    (spy-on 'indium-breakpoint-add :and-call-through)
    (with-js2-buffer "let a = 2;"
      (goto-char (point-min))
      (let ((loc (make-indium-location))
	    (condition "condition"))
	(indium-breakpoint-add loc condition)
	;; simulate getting the breakpoint ID from a backend
	(setf (indium-breakpoint-id (indium-breakpoint-at-point)) 'id)
	(with-fake-indium-connection
	  (indium-breakpoint-restore-breakpoints)
	  (expect #'indium-backend-add-breakpoint :to-have-been-called)
	  (expect #'indium-breakpoint-add :to-have-been-called-with loc condition))))))

(provide 'indium-breakpoint-test)
;;; indium-breakpoint-test.el ends here

// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Explicitly register session-timeout controller for production
import SessionTimeoutController from "controllers/session_timeout_controller"
application.register("session-timeout", SessionTimeoutController)

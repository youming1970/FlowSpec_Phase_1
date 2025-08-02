package com.example.service;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserService {

    /**
     * @ServiceSpec
     * operationId: "createUser"
     * description: "Create a new user account"
     * preconditions:
     *   "email_validation": {
     *     "and": [
     *       {"!=": [{"var": "request.body.email"}, null]},
     *       {"regex": [{"var": "request.body.email"}, "^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$"]}
     *     ]
     *   }
     *   "password_strength": {
     *     ">=": [{"strlen": [{"var": "request.body.password"}]}, 8]
     *   }
     * postconditions:
     *   "successful_creation": {
     *     "and": [
     *       {"==": [{"var": "response.status"}, 201]},
     *       {"!=": [{"var": "response.body.userId"}, null]}
     *     ]
     *   }
     */
    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody CreateUserRequest request) {
        return ResponseEntity.status(201).body(userService.create(request));
    }

    /**
     * @ServiceSpec
     * operationId: "getUser"
     * description: "Retrieve user by ID"
     * preconditions:
     *   "valid_user_id": {
     *     "!=": [{"var": "request.path.userId"}, null]
     *   }
     * postconditions:
     *   "successful_retrieval": {
     *     "==": [{"var": "response.status"}, 200]
     *   }
     */
    @GetMapping("/{userId}")
    public ResponseEntity<User> getUser(@PathVariable String userId) {
        return ResponseEntity.ok(userService.findById(userId));
    }
}
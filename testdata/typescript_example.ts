import { Injectable } from '@nestjs/common';
import { User } from './types/User';

@Injectable()
export class UserService {

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
    async createUser(request: CreateUserRequest): Promise<User> {
        return this.userRepository.save(new User(request));
    }

    // @ServiceSpec
    // operationId: "getUser"
    // description: "Retrieve user by ID"
    // preconditions:
    //   "valid_user_id": {
    //     "!=": [{"var": "request.path.userId"}, null]
    //   }
    // postconditions:
    //   "successful_retrieval": {
    //     "==": [{"var": "response.status"}, 200]
    //   }
    async getUser(userId: string): Promise<User> {
        return this.userRepository.findById(userId);
    }
}
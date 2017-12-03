import Vue from 'vue';

import { current } from '../helper/semester';

export default {
    namespaced: true,
    state: {
        initialised: false,
        data: []
    },
    mutations: {
        /**
         * Set one or all courses or their sprints
         * @param state
         * @param payload
         */
        set: (state, payload) => {
            if (payload.courses) {
                Vue.set(state, 'data', payload.courses);
            }

            if (payload.course) {
                const isPresent = state.data
                    .find(course => course.id === payload.course.id);

                if (isPresent) {
                    Vue.set(state, 'data', state.data.map(c =>
                        (c.id === payload.course.id ? payload.course : c),
                    ));
                } else {
                    state.data.push(payload.course);
                }
            }

            if (payload.sprint) {
                const courseIndex = state.data.findIndex(c => c.id === payload.sprint.course_id);

                if (courseIndex < 0) {
                    throw new Error('Cannot add sprint to non existing course!');
                }

                const course = state.data[courseIndex];

                if (!course.sprints || course.sprints.length < 1) {
                    course.sprints = [payload.sprint];
                } else {
                    const isPresent = course.sprints.find(sprint => sprint.id === payload.sprint.id);

                    if (isPresent) {
                        course.sprints = course.sprints.map(sprint => (sprint.id === payload.sprint.id ? payload.sprint : sprint));
                    } else {
                        course.sprints.push(payload.sprint);
                    }
                }

                Vue.set(state.data, courseIndex, course);
            }
        },

        /**
         * Remove a sprint from a course
         * @param state
         * @param payload
         */
        removeSprint: (state, payload) => {
            const courseIndex = state.data.findIndex(c => c.id === payload.course_id);

            if (courseIndex < 0) {
                throw new Error('Cannot remove sprint from non existing course!');
            }

            const course = state.data[courseIndex];
            course.sprints = course.sprints.filter(s => s.id !== payload.id);

            Vue.set(state.data, courseIndex, course);
        }
    },
    actions: {
        /**
         * Initialises the courses store
         * @param state
         * @param dispatch
         */
        init({state, dispatch}) {
            if (!state.initialised) {
                dispatch('fetch').then(() => {
                    state.initialised = true;
                });
            }
        },

        /**
         * Fetches all courses from the API and updates store
         * @param commit
         * @returns {Promise}
         */
        fetch({commit}) {
            return new Promise((resolve, reject) => {
                Vue.http.get('/courses').then((response) => {
                    commit('set', {
                        courses: response.body,
                    });

                    resolve(response.body);
                }, reject);
            });
        },

        /**
         * Saves a course to the API and updates store
         * @param commit
         * @param payload (course)
         * @returns {Promise}
         */
        save({commit}, payload) {
            // clone course object so we can change stuff
            const course = Object.assign({}, payload.course);

            // extract semester year and type from semester info
            const semesterSplit = course.semester.split('*');
            course.semester_type = semesterSplit[0];
            course.semester_year = parseInt(semesterSplit[1], 10);
            delete course.semester;

            return new Promise((resolve, reject) => {
                Vue.http.post('/courses', course).then((response) => {
                    commit('set', {
                        course: response.body,
                    });

                    resolve(response.body);
                }, reject);
            });
        },

        /**
         * Patches a given field of a given course with a given value
         * @param commit
         * @param payload (id, field, value)
         * @returns {Promise}
         */
        patch({commit}, payload) {
            return new Promise((resolve, reject) => {
                const data = {};
                data[payload.field] = payload.value;

                Vue.http.patch(`/courses/${payload.id}`, data).then((response) => {
                    commit('set', {
                        course: response.body,
                    });

                    resolve(response.body);
                }, reject);
            });
        },

        /**
         * Add a sprint to a given course
         * @param commit
         * @param payload (id, sprint)
         * @returns {Promise}
         */
        addSprint({commit}, payload) {
            return new Promise((resolve, reject) => {
                Vue.http.post(`/courses/${payload.id}/sprints`, payload.sprint).then((response) => {
                    commit('set', {
                        sprint: response.body,
                    });

                    resolve(response.body);
                }, reject);
            });
        },
    },
    getters: {
        /**
         * All courses
         * @param state
         */
        all: state => state.initialised
            ? state.data.sort((a, b) => a.position > b.position)
            : [],

        /**
         * Find a course by id
         * @param state
         */
        byId: state => id => state.initialised
            ? state.data.find(c => c.id === id)
            : null,

        /**
         * A template for a new course
         * @returns {{semester: string}}
         */
        new: () => {
            return {
                semester: current().valueString,
            }
        },
    }
}
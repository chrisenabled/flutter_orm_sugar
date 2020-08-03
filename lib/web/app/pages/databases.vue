<template>
    <q-page class="column justify-center q-gutter-xl">
        <div v-if="config" class="row justify-center q-gutter-x-xl">
            <q-card dark class="col-4 ">
                <q-card-section>
                    <div class="text-h6">Firestore</div>
                    <div class="text-subtitle2">gcloud firestore (external)</div>
                </q-card-section>

                <q-card-section v-if="config.repositories.firestore">
                    <q-input standout dense dark hint="collection base path" 
                        :label="config.repositories.firestore.name" disable readonly>
                    </q-input>
                </q-card-section>

                <q-card-section v-if="config.repositories.firestore == null">
                    <q-input standout dark v-model="firestoreRoot" label="Enter firestore base path and activate"></q-input>
                </q-card-section>

                <q-card-actions align="center">
                    <q-btn disabled v-if="config.repositories.firestore" flat no-caps>
                        Activated</q-btn>
                    <q-btn v-else flat no-caps 
                        @click="activateDb('firestore', firestoreRoot)"
                        :loading="submitting.firestore"
                        label="Activate"
                    >
                        <template v-slot:loading>
                            <q-spinner-facebook />
                        </template>
                    </q-btn>
                </q-card-actions>
            </q-card>
            <q-card primary class="col-4 ">
                <q-card-section>
                    <div class="text-h6">SQLite</div>
                    <div class="text-subtitle2">sqlite database (local)</div>
                </q-card-section>

                <q-card-section v-if="config.repositories.sqlite">
                    <q-input standout dense hint="Database Name" :label="config.repositories.sqlite.name"  disable readonly>
                    </q-input>
                </q-card-section>

                <q-card-section v-if="config.repositories.sqlite == null">
                    <q-input standout v-model="databaseName" label="Enter Database Name and Activate"></q-input>
                </q-card-section>

                <q-card-actions align="center">
                    <q-btn disabled v-if="config.repositories.sqlite" flat no-caps>
                        Activated</q-btn>
                    <q-btn v-else flat no-caps @click="activateDb('sqlite', databaseName)">Activate</q-btn>
                </q-card-actions>
            </q-card>
        </div>
        <div v-if="config" class="row justify-center q-gutter-x-xl">
            <q-card class="col-4 bg-warning">
                <q-card-section>
                    <div class="text-h6">Api</div>
                    <div class="text-subtitle2">restful service (external)</div>
                </q-card-section>

                <q-card-section v-if="config.repositories.api">
                    <q-input standout dense hint="Uri base path" 
                        :label="config.repositories.api.name"  disable readonly>
                    </q-input>
                </q-card-section>

                <q-card-section v-if="config.repositories.api == null">
                    <q-input standout v-model="apiBaseUrl" label="Enter Uri base path and Activate"></q-input>
                </q-card-section>

                <q-card-actions align="center">
                    <q-btn disabled v-if="config.repositories.api" flat no-caps>
                        Activated</q-btn>
                    <q-btn v-else flat no-caps @click="activateDb('api', apiBaseUrl)">Activate</q-btn>
                </q-card-actions>
            </q-card>
            <q-card class="col-4 my-card bg-accent text-white">
                <q-card-section>
                    <div class="text-h6">SharedPref</div>
                    <div class="text-subtitle2">key-value store (local)</div>
                </q-card-section>

                <q-card-section v-if="config.repositories.sharedPref">
                    <q-input standout dense dark hint="Database Name" 
                        :label="config.repositories.sharedPref.name"  disable readonly>
                    </q-input>
                </q-card-section>

                <q-card-section v-if="config.repositories.sharedPref == null">
                    <q-input standout dark v-model="sharedPrefPrefix" 
                        label="Enter Database Name and Activate"></q-input>
                </q-card-section>

                <q-card-actions align="center">
                    <q-btn disabled v-if="config.repositories.sharedPref" flat no-caps>
                        Activated</q-btn>
                    <q-btn v-else flat no-caps @click="activateDb('sharedPref', sharedPrefPrefix)">Activate</q-btn>
                </q-card-actions>
            </q-card>
        </div>
        <div v-else class="self-center">
            <q-spinner-cube color="orange" size="5.5em"></q-spinner-cube>
        </div>
    </q-page>
</template>

<script>
module.exports =  {
    data () {
       return {
           submitting: {
               firestore: false,
               api: false,
               sqlite: false,
               sharedPref: false
           },
           firestoreRoot:'',
           apiBaseUrl:'',
           sharedPrefPrefix:'',
           databaseName:'',
       } 
    },
    mounted: function () {
        this.$nav.current = 'Databases'
    },
    computed: {
        config() {
            return this.$store.config.data
        }
    },
    methods: {
        activateDb(dbType, name) {
            this.submitting[dbType] = true
            setTimeout(() => {
                this.$actions.activateDb({type: dbType, name: name})
                .then((status) => this.submitting[dbType] = false)
            }, 1000)
            
        }
    }
}
</script>
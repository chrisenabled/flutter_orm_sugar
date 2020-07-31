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
                    <q-input standout dark v-model="text" label="Enter collection base path and activate"></q-input>
                </q-card-section>

                <q-card-actions align="center">
                    <q-btn disabled v-if="config.repositories.firestore" flat no-caps>
                        Activated</q-btn>
                    <q-btn v-else flat no-caps>Activate</q-btn>
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
                    <q-input standout v-model="text" label="Enter Database Name and Activate"></q-input>
                </q-card-section>

                <q-card-actions align="center">
                    <q-btn disabled v-if="config.repositories.sqlite" flat no-caps>
                        Activated</q-btn>
                    <q-btn v-else flat no-caps>Activate</q-btn>
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
                    <q-input standout dense hint="Uri base path" :label="config.repositories.api.name"  disable readonly>
                    </q-input>
                </q-card-section>

                <q-card-section v-if="config.repositories.api == null">
                    <q-input standout v-model="text" label="Enter Uri base path and Activate"></q-input>
                </q-card-section>

                <q-card-actions align="center">
                    <q-btn disabled v-if="config.repositories.api" flat no-caps>
                        Activated</q-btn>
                    <q-btn v-else flat no-caps>Activate</q-btn>
                </q-card-actions>
            </q-card>
            <q-card class="col-4 my-card bg-accent text-white">
                <q-card-section>
                    <div class="text-h6">SharedPref</div>
                    <div class="text-subtitle2">key-value store (local)</div>
                </q-card-section>

                <q-card-section v-if="config.repositories.sharedpref">
                    <q-input standout dense dark hint="Database Name" 
                        :label="config.repositories.sharedpref.name"  disable readonly>
                    </q-input>
                </q-card-section>

                <q-card-section v-if="config.repositories.sharedpref == null">
                    <q-input standout dark v-model="text" label="Enter Database Name and Activate"></q-input>
                </q-card-section>

                <q-card-actions align="center">
                    <q-btn disabled v-if="config.repositories.sharedpref" flat no-caps>
                        Activated</q-btn>
                    <q-btn v-else flat no-caps>Activate</q-btn>
                </q-card-actions>
            </q-card>
        </div>
        <div v-else class="self-center">
            <q-spinner-cube color="orange" size="5.5em"></q-spinner-cube>
        </div>
        <!-- <div class="self-center">
            <q-banner rounded inline-actions class="text-white bg-red">
                <q-icon name="ti-face-sad"></q-icon> &nbsp; {{ name }}
                <template v-slot:action>
                    <q-btn flat color="white" label="Retry" />
                </template>
            </q-banner>
        </div> -->
    </q-page>
</template>

<script>
module.exports =  {
    data () {
       return {
           text:'',
           name : 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'
       } 
    },
    mounted: function () {
        this.$nav.current = 'Databases'
    },
    computed: {
        config() {
            return this.$store.config.data
        }
    }
}
</script>
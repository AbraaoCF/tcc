package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/go-redis/redis/v8"
)

var (
	redisClient *redis.Client
	ctx         = context.Background()
)

func initRedis() {
	redisClient = redis.NewClient(&redis.Options{
		Addr:     "redis:6379", // Redis server address
		Password: "",               // No password set
		DB:       0,                // Use default DB
	})

	_, err := redisClient.Ping(ctx).Result()
	if err != nil {
		log.Fatalf("Could not connect to Redis: %v", err)
	}
}

func getLogs(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	fmt.Println(id)
	logs, err := redisClient.LRange(ctx, id, 0, -1).Result()
	if err != nil {
		http.Error(w, fmt.Sprintf("Could not fetch logs from Redis: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(logs)
}

func postLog(w http.ResponseWriter, r *http.Request) {
	var logEntry map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&logEntry); err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}
	id := logEntry["id"].(string)
	timestamp := logEntry["timestamp"]

	logEntryBytes, err := json.Marshal(timestamp)
	if err != nil {
		http.Error(w, fmt.Sprintf("Could not serialize log entry: %v", err), http.StatusInternalServerError)
		return
	}

	if err := redisClient.RPush(ctx, id, logEntryBytes).Err(); err != nil {
		http.Error(w, fmt.Sprintf("Could not store log entry in Redis: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func main() {
	initRedis()

	server := &http.Server{
		Addr:         ":8080",
		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}


	mux := http.NewServeMux()

	mux.HandleFunc("/logs/{id}", getLogs)
	mux.HandleFunc("/log", postLog)
	server.Handler = mux

	fmt.Println("Starting server on :8080")
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("Could not start server: %v", err)
	}}

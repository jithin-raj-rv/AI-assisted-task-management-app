-- Fix for real-time delete notifications
-- Run this in your Supabase SQL Editor

ALTER TABLE todos REPLICA IDENTITY FULL;

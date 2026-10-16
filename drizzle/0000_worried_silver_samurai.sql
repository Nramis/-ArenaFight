CREATE TABLE `rooms` (
	`code` text PRIMARY KEY NOT NULL,
	`host_hash` text NOT NULL,
	`guest_hash` text,
	`host_name` text NOT NULL,
	`guest_name` text DEFAULT '' NOT NULL,
	`host_fighter` text NOT NULL,
	`guest_fighter` text DEFAULT 'nikita' NOT NULL,
	`stage` text DEFAULT 'rooftop' NOT NULL,
	`host_ready` integer DEFAULT 0 NOT NULL,
	`guest_ready` integer DEFAULT 0 NOT NULL,
	`status` text DEFAULT 'waiting' NOT NULL,
	`session` integer DEFAULT 0 NOT NULL,
	`seed` integer DEFAULT 1 NOT NULL,
	`created_at` integer NOT NULL,
	`expires_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `signals` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`code` text NOT NULL,
	`session` integer NOT NULL,
	`seat` integer NOT NULL,
	`payload` text NOT NULL,
	FOREIGN KEY (`code`) REFERENCES `rooms`(`code`) ON UPDATE no action ON DELETE cascade
);

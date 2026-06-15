// Authoritative render of Radix Themes 3 — the GOLDEN source. We render each
// component (and a composed demo) in isolation, keyed by ?c=<id>, so Playwright
// can screenshot one per page; the index (no ?c=) is the human-reviewable gallery.
// This is upstream's real output — our Halogen port is diffed against it.
import React from "react";
import { createRoot } from "react-dom/client";
import "@radix-ui/themes/styles.css";
// Bundle Inter (Radix Themes' intended typeface) so the render is deterministic —
// headless Chromium has no system sans, so without this the golden falls back to
// monospace. Self-hosted woff2 → identical pixels in CI and in our port's capture.
import "@fontsource-variable/inter";
import {
  Theme,
  Button,
  Checkbox,
  Switch,
  TextField,
  Card,
  Separator,
  Badge,
  Flex,
  Box,
  Text,
  Heading,
} from "@radix-ui/themes";

type Page = { id: string; label: string; node: React.ReactNode };

// Each page is wrapped in <Theme> at mount; here we describe just the content.
const PAGES: Page[] = [
  {
    id: "button",
    label: "Button",
    node: (
      <Flex direction="column" gap="3" align="start">
        <Flex gap="3" align="center">
          <Button variant="solid">Solid</Button>
          <Button variant="soft">Soft</Button>
          <Button variant="outline">Outline</Button>
          <Button variant="surface">Surface</Button>
          <Button variant="ghost">Ghost</Button>
        </Flex>
        <Flex gap="3" align="center">
          <Button size="1">Size 1</Button>
          <Button size="2">Size 2</Button>
          <Button size="3">Size 3</Button>
          <Button disabled>Disabled</Button>
        </Flex>
      </Flex>
    ),
  },
  {
    id: "checkbox",
    label: "Checkbox",
    node: (
      <Flex direction="column" gap="2">
        <Text as="label" size="2">
          <Flex gap="2" align="center">
            <Checkbox defaultChecked /> Checked
          </Flex>
        </Text>
        <Text as="label" size="2">
          <Flex gap="2" align="center">
            <Checkbox /> Unchecked
          </Flex>
        </Text>
        <Text as="label" size="2">
          <Flex gap="2" align="center">
            <Checkbox disabled defaultChecked /> Disabled
          </Flex>
        </Text>
      </Flex>
    ),
  },
  {
    id: "switch",
    label: "Switch",
    node: (
      <Flex gap="4" align="center">
        <Switch defaultChecked />
        <Switch />
        <Switch disabled defaultChecked />
        <Switch size="1" defaultChecked />
        <Switch size="3" defaultChecked />
      </Flex>
    ),
  },
  {
    id: "textfield",
    label: "TextField",
    node: (
      <Flex direction="column" gap="3" style={{ maxWidth: 320 }}>
        <TextField.Root placeholder="Search the docs…" />
        <TextField.Root size="3" placeholder="Larger field" defaultValue="m@example.com" />
      </Flex>
    ),
  },
  {
    id: "badge",
    label: "Badge",
    node: (
      <Flex gap="2" align="center">
        <Badge color="green">Complete</Badge>
        <Badge color="orange">In progress</Badge>
        <Badge color="red">Failed</Badge>
        <Badge variant="solid">Solid</Badge>
      </Flex>
    ),
  },
  {
    id: "card",
    label: "Card",
    node: (
      <Box style={{ maxWidth: 320 }}>
        <Card>
          <Flex gap="3" align="center">
            <Box>
              <Text as="div" size="2" weight="bold">
                Teodros Girmay
              </Text>
              <Text as="div" size="2" color="gray">
                Engineering
              </Text>
            </Box>
          </Flex>
        </Card>
      </Box>
    ),
  },
  {
    id: "separator",
    label: "Separator",
    node: (
      <Flex direction="column" gap="3" style={{ maxWidth: 240 }}>
        <Text size="2">Above</Text>
        <Separator size="4" />
        <Text size="2">Below</Text>
      </Flex>
    ),
  },
  // The composed demo — the "looks like a finished product" target.
  {
    id: "signin",
    label: "Sign-in card",
    node: (
      <Box style={{ maxWidth: 400 }}>
        <Card size="4">
          <Heading as="h3" size="6" trim="start" mb="5">
            Sign in
          </Heading>
          <Box mb="5">
            <Flex direction="column" gap="1">
              <Text as="label" size="2" weight="medium">
                Email address
              </Text>
              <TextField.Root placeholder="you@example.com" />
            </Flex>
          </Box>
          <Box mb="5">
            <Flex direction="column" gap="1">
              <Flex justify="between">
                <Text as="label" size="2" weight="medium">
                  Password
                </Text>
                <Text size="2">
                  <a href="#">Forgot password?</a>
                </Text>
              </Flex>
              <TextField.Root placeholder="Enter your password" />
            </Flex>
          </Box>
          <Flex align="center" gap="2" mb="5">
            <Text as="label" size="2">
              <Flex gap="2" align="center">
                <Checkbox defaultChecked /> Remember me
              </Flex>
            </Text>
          </Flex>
          <Flex justify="end" gap="3">
            <Button variant="soft" color="gray">
              Create account
            </Button>
            <Button>Sign in</Button>
          </Flex>
        </Card>
      </Box>
    ),
  },
];

function currentId(): string {
  const m = location.search.match(/[?&]c=([^&]+)/);
  return m ? decodeURIComponent(m[1]) : "";
}

function Index() {
  return (
    <Box p="6" style={{ maxWidth: 900, margin: "0 auto" }}>
      <Heading size="7" mb="1">
        Radix Themes 3.3.0 — golden source
      </Heading>
      <Text as="p" color="gray" mb="5">
        Upstream render. Each card is the authoritative target our Halogen port is
        pixel-diffed against. Click a title to see it isolated (the Playwright page).
      </Text>
      <Flex direction="column" gap="4">
        {PAGES.map((p) => (
          <Card key={p.id} size="2">
            <Heading size="2" mb="3" color="gray">
              <a href={`?c=${p.id}`} style={{ color: "inherit", textDecoration: "none" }}>
                {p.label}
              </a>
            </Heading>
            {p.node}
          </Card>
        ))}
      </Flex>
    </Box>
  );
}

const id = currentId();
const page = PAGES.find((p) => p.id === id);
const content = page ? <Box p="6">{page.node}</Box> : <Index />;

createRoot(document.getElementById("root")!).render(
  <Theme
    accentColor="indigo"
    grayColor="slate"
    radius="medium"
    appearance="light"
    style={{ ["--default-font-family" as string]: "'Inter Variable', sans-serif" }}
  >
    {content}
  </Theme>,
);
